"""Static catalog of waste categories and the deterministic keyword fallback.

These are intentionally shared between the trained model path (``classifier``)
and the rule-based fallback (``services``) so both produce identical output
shapes.
"""

CLASSIFICATION_CATEGORIES = [
    {
        "category": "Plastic (PET/HDPE)",
        "slug": "plastic",
        "recyclable": True,
        "instructions": "Rinse clean and remove caps before bundling for collection or trade-in.",
        "estimated_price_ugx_kg": 400,
        "eco_points_per_kg": 15,
        "confidence_base": 0.94,
    },
    {
        "category": "Organic / Food Waste",
        "slug": "organic",
        "recyclable": True,
        "instructions": "Compostable. Separate from dry non-biodegradable waste.",
        "estimated_price_ugx_kg": 150,
        "eco_points_per_kg": 10,
        "confidence_base": 0.91,
    },
    {
        "category": "Paper & Cardboard",
        "slug": "paper",
        "recyclable": True,
        "instructions": "Keep dry and flatten boxes to conserve space.",
        "estimated_price_ugx_kg": 300,
        "eco_points_per_kg": 12,
        "confidence_base": 0.89,
    },
    {
        "category": "Glass Bottles & Jars",
        "slug": "glass",
        "recyclable": True,
        "instructions": "Handle with care to prevent breakage. Clean before disposal.",
        "estimated_price_ugx_kg": 250,
        "eco_points_per_kg": 10,
        "confidence_base": 0.92,
    },
    {
        "category": "Metal / Aluminum Cans",
        "slug": "metal",
        "recyclable": True,
        "instructions": "Crush cans to save space. High recyclability value.",
        "estimated_price_ugx_kg": 1200,
        "eco_points_per_kg": 25,
        "confidence_base": 0.96,
    },
    {
        "category": "Electronic Waste (E-Waste)",
        "slug": "e-waste",
        "recyclable": True,
        "instructions": "Do not mix with general waste. Drop at authorized e-waste recycling center.",
        "estimated_price_ugx_kg": 2500,
        "eco_points_per_kg": 50,
        "confidence_base": 0.88,
    },
]

CATEGORY_BY_SLUG = {c["slug"]: c for c in CLASSIFICATION_CATEGORIES}
SUPPORTED_SLUGS = sorted(CATEGORY_BY_SLUG.keys())

# Filename keywords -> category slug. Used as an explainable fallback when no
# trained model is deployed or when the model is uncertain.
KEYWORD_SLUGS = {
    "plastic": "plastic",
    "bottle": "plastic",
    "pet": "plastic",
    "bag": "plastic",
    "organic": "organic",
    "food": "organic",
    "peel": "organic",
    "paper": "paper",
    "cardboard": "paper",
    "carton": "paper",
    "glass": "glass",
    "jar": "glass",
    "bottle_glass": "glass",
    "can": "metal",
    "metal": "metal",
    "aluminum": "metal",
    "aluminium": "metal",
    "tins": "metal",
    "e-waste": "e-waste",
    "electronic": "e-waste",
    "battery": "e-waste",
    "computer": "e-waste",
}


def resolve_keyword_slug(filename):
    """Return the first matching category slug for a filename, or None."""
    text = (filename or "").lower().replace("_", " ").replace("-", " ")
    for word in text.split():
        for keyword, slug in KEYWORD_SLUGS.items():
            if keyword in word or keyword == word:
                return slug
    for keyword, slug in KEYWORD_SLUGS.items():
        if keyword in text:
            return slug
    return None