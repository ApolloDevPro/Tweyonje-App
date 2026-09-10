"""Classification service facade.

``classify_waste_image`` is the public entry point used by views. It delegates
to the trained-model pipeline (``classifier``) which degrades gracefully to the
deterministic keyword heuristic when no model is deployed.
"""
from .classifier import classify_waste_image_bytes
from .categories import CLASSIFICATION_CATEGORIES  # noqa: F401 (public catalog)


def classify_waste_image(image_file):
    """Classify a Django UploadedFile. Returns the prediction payload dict."""
    payload = image_file.read()
    image_file.seek(0)
    result = classify_waste_image_bytes(payload, filename=image_file.name or "")
    return {k: v for k, v in result.items() if k != "matched_filename"}