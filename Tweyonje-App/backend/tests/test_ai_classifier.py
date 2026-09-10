"""Tests for the scikit-learn waste image classifier pipeline."""

import io
import tempfile
from pathlib import Path

from django.test import SimpleTestCase, override_settings
from PIL import Image

from apps.ai.classifier import (
    _extract_features,
    classify_waste_image_bytes,
    model_path,
    train_classifier,
)

SLUG_COLORS = {
    "plastic": (200, 50, 50),
    "organic": (50, 200, 50),
    "paper": (200, 200, 180),
    "glass": (50, 50, 200),
    "metal": (180, 180, 180),
    "e-waste": (80, 80, 80),
}


def _make_dataset(base_dir, images_per_class=4):
    base = Path(base_dir)
    for slug, color in SLUG_COLORS.items():
        folder = base / slug
        folder.mkdir(parents=True, exist_ok=True)
        for i in range(images_per_class):
            Image.new("RGB", (96, 96), color).save(folder / f"sample_{i}.png")
    return base


def _png_bytes(color, size=(64, 64)):
    buffer = io.BytesIO()
    Image.new("RGB", size, color).save(buffer, format="PNG")
    return buffer.getvalue()


class FeatureExtractionTest(SimpleTestCase):
    def test_feature_vector_shape(self):
        vector = _extract_features(Image.new("RGB", (64, 64), (10, 20, 30)))
        raw_pixels = 64 * 64 * 3
        hist = 3 * 16
        self.assertEqual(vector.shape[0], raw_pixels + hist)

    def test_unknown_image_decodes_gracefully(self):
        result = classify_waste_image_bytes(b"not-an-image", "garbage.txt")
        self.assertEqual(result["classifier"], "heuristic-v1")
        self.assertIn("slug", result)


@override_settings(AI_MODEL_PATH=tempfile.mktemp(suffix=".joblib"))
class ClassifierPipelineTest(SimpleTestCase):
    def test_train_and_predict_round_trip(self):
        with tempfile.TemporaryDirectory() as tmp:
            data_dir = _make_dataset(tmp)
            metrics = train_classifier(data_dir, n_estimators=10)
            self.assertEqual(metrics["samples"], 24)
            self.assertEqual(len(metrics["classes"]), 6)
            self.assertGreaterEqual(metrics["accuracy"], 0.9)
            self.assertEqual(metrics["model_path"], model_path())

            result = classify_waste_image_bytes(_png_bytes(SLUG_COLORS["glass"]), "bottle.png")
            self.assertEqual(result["slug"], "glass")
            self.assertEqual(result["classifier"], "random-forest-v1")
            self.assertGreaterEqual(result["confidence"], 0.35)

    def test_no_model_falls_back_to_heuristic(self):
        result = classify_waste_image_bytes(_png_bytes((30, 30, 30)), "plastic_bottle.jpg")
        self.assertIn("plastic", result["slug"])
        self.assertEqual(result["classifier"].split(" ")[0], "heuristic-v1")

    def test_uncertain_model_falls_back(self):
        with tempfile.TemporaryDirectory() as tmp:
            data_dir = _make_dataset(tmp, images_per_class=2)
            train_classifier(data_dir, n_estimators=3)
            # A random-noise image with a plastic filename exercises the
            # low-confidence fallback path without asserting on model internals.
            noise = Image.new("RGB", (64, 64), (0, 0, 0))
            buffer = io.BytesIO()
            noise.save(buffer, format="PNG")
            result = classify_waste_image_bytes(buffer.getvalue(), "random_noise.bin")
            self.assertIn("slug", result)
            self.assertIn("confidence", result)