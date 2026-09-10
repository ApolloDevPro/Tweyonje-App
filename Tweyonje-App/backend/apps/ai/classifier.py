"""Trainable waste image classifier.

A genuine machine-learning pipeline built on scikit-learn: images are decoded
with Pillow, reduced to a compact feature vector (downsampled RGB pixels +
per-channel color histograms), and classified with a Random Forest. If no
trained model exists (or the model is too uncertain), predictions gracefully
fall back to the deterministic filename-keyword heuristic in ``categories``.
"""
import logging
import os
from pathlib import Path
from io import BytesIO

import numpy as np
from django.conf import settings
from PIL import Image
from PIL import UnidentifiedImageError

from .categories import CATEGORY_BY_SLUG, SUPPORTED_SLUGS, resolve_keyword_slug

logger = logging.getLogger(__name__)

# Downsampled spatial resolution. 64x64x3 = 12,288 raw pixel features plus
# 48 histogram features -- small enough to keep inference fast on mobile CPUs.
_FEATURE_SIZE = (64, 64)
_HIST_BINS = 16

# Below this confidence the model is considered "uncertain" and the classifier
# refuses to commit, falling back to the explainable heuristic.
MIN_CONFIDENCE = 0.35

_IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
_DEFAULT_N_ESTIMATORS = 200


def model_path():
    """Absolute path of the serialized model (joblib)."""
    configured = getattr(settings, "AI_MODEL_PATH", "") or ""
    if configured:
        return str(configured)
    return str(Path(settings.MEDIA_ROOT) / "ai" / "waste_classifier.joblib")


def _extract_features(pil_image):
    """Reduce a PIL image to a normalized feature vector."""
    img = pil_image.convert("RGB").resize(_FEATURE_SIZE, Image.BILINEAR)
    arr = np.asarray(img, dtype=np.float32) / 255.0
    pixels = arr.reshape(-1)
    hist_parts = []
    for channel in range(3):
        counts, _ = np.histogram(arr[:, :, channel], bins=_HIST_BINS, range=(0.0, 1.0))
        hist_parts.append(counts.astype(np.float32))
    hist = np.concatenate(hist_parts)
    total = hist.sum() or 1.0
    hist = hist / total
    return np.concatenate([pixels, hist]).astype(np.float32)


def _iter_category_images(data_dir):
    """Yield (slug, image_path) for every readable image in data_dir."""
    for folder in sorted(data_dir.iterdir()):
        if not folder.is_dir():
            continue
        slug = folder.name.strip().lower()
        if slug not in CATEGORY_BY_SLUG:
            logger.warning("Ignoring unknown category folder: %s", folder.name)
            continue
        for image_path in sorted(folder.iterdir()):
            if image_path.suffix.lower() in _IMAGE_EXTS:
                yield slug, image_path


def train_classifier(data_dir, epochs=None, n_estimators=None):
    """Train a Random Forest waste classifier from a label-per-folder dataset.

    Folder names must match the slugs in ``categories.CLASSIFICATION_CATEGORIES``
    (e.g. ``<data-dir>/plastic/``, ``<data-dir>/organic/``). Returns a metrics
    dict and writes a joblib dump to ``settings.AI_MODEL_PATH``.
    """
    try:
        import joblib
        from sklearn.ensemble import RandomForestClassifier
    except ImportError as exc:  # pragma: no cover - guarded by requirements
        raise RuntimeError(
            "scikit-learn and joblib are required to train the classifier. "
            "Install with: pip install scikit-learn joblib"
        ) from exc

    data_dir = Path(data_dir)
    if not data_dir.is_dir():
        raise ValueError(f"Training data directory does not exist: {data_dir}")

    samples, labels, filenames = [], [], []
    for slug, image_path in _iter_category_images(data_dir):
        try:
            with Image.open(image_path) as img:
                features = _extract_features(img)
        except (UnidentifiedImageError, OSError, ValueError) as exc:
            logger.warning("Skipping unreadable image %s: %s", image_path, exc)
            continue
        samples.append(features)
        labels.append(slug)
        filenames.append(str(image_path))

    present = set(labels)
    missing = set(SUPPORTED_SLUGS) - present
    if len(samples) == 0:
        raise ValueError(f"No readable images found under {data_dir}")
    if len(present) < len(SUPPORTED_SLUGS):
        logger.warning("Categories with no training samples: %s", ", ".join(sorted(missing)))

    forest = RandomForestClassifier(
        n_estimators=n_estimators or _DEFAULT_N_ESTIMATORS,
        random_state=42,
        n_jobs=-1,
        class_weight="balanced",
    )
    labels_arr = np.asarray(labels)
    forest.fit(np.asarray(samples), labels_arr)
    accuracy = float(np.mean(forest.predict(np.asarray(samples)) == labels_arr))

    os.makedirs(Path(model_path()).parent, exist_ok=True)
    joblib.dump(forest, model_path())

    distribution = {slug: labels.count(slug) for slug in present}
    return {
        "model_path": model_path(),
        "samples": len(samples),
        "epochs": epochs,
        "n_estimators": forest.n_estimators,
        "classes": sorted(present),
        "accuracy": accuracy,
        "class_distribution": distribution,
    }


def _load_model():
    """Load the trained model, or None when unavailable/broken."""
    try:
        import joblib

        if not os.path.exists(model_path()):
            return None
        return joblib.load(model_path())
    except Exception:
        logger.exception("Failed to load classifier model at %s", model_path())
        return None


def _model_predict(model, features):
    """Return (slug, confidence) from the trained model, or (None, 0.0)."""
    if model is None:
        return None, 0.0
    try:
        proba = model.predict_proba(features)[0]
        idx = int(np.argmax(proba))
        slug = str(model.classes_[idx])
        confidence = float(proba[idx])
        if slug not in CATEGORY_BY_SLUG:
            return None, 0.0
        return slug, confidence
    except Exception:
        logger.exception("Model prediction failed; using fallback")
        return None, 0.0


def classify_waste_image_bytes(image_bytes, filename=""):
    """Classify raw image bytes. Returns a dict identical in shape to the
    heuristic result, tagged with the classifier that produced it."""
    try:
        with Image.open(BytesIO(image_bytes)) as img:
            img.load()
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        logger.warning("Unable to decode image %r: %s", filename, exc)
        return _heuristic_result(filename, "heuristic-v1")

    features = _extract_features(img).reshape(1, -1)
    slug, confidence = _model_predict(_load_model(), features)

    if slug is not None and confidence >= MIN_CONFIDENCE:
        return _build_result(slug, confidence, "random-forest-v1", filename)

    # Model absent or too uncertain: deterministic, explainable fallback.
    return _heuristic_result(filename, f"heuristic-v1 (model confidence {confidence:.2f})")


def _heuristic_result(filename, classifier_tag):
    slug = resolve_keyword_slug(filename) or "plastic"
    selected = CATEGORY_BY_SLUG[slug]
    confidence = round(selected["confidence_base"] - 0.02, 4)
    return _build_result(slug, confidence, classifier_tag, filename)


def _build_result(slug, confidence, classifier_tag, filename):
    selected = CATEGORY_BY_SLUG[slug]
    return {
        "category": selected["category"],
        "slug": selected["slug"],
        "confidence": round(confidence, 4),
        "recyclable": selected["recyclable"],
        "instructions": selected["instructions"],
        "estimated_value_ugx_kg": selected["estimated_price_ugx_kg"],
        "eco_points_potential_kg": selected["eco_points_per_kg"],
        "classifier": classifier_tag,
        "matched_filename": filename,
    }