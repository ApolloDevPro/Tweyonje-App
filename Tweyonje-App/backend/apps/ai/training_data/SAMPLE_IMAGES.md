# Sample Training Images Guide

Since actual training images are not included in this repository (due to size), here's how to populate the dataset:

## Quick Start with Public Datasets

### 1. TrashNet Dataset (Recommended)

```powershell
# Download and extract TrashNet
Invoke-WebRequest -Uri "https://github.com/garythung/trashnet/archive/master.zip" -OutFile "trashnet.zip"
Expand-Archive -Path "trashnet.zip" -DestinationPath "."

# Reorganize into our folder structure
# TrashNet has: cardboard, glass, metal, paper, plastic, trash
# Map to our categories
Copy-Item "trashnet-master/dataset-resized/plastic/*" "plastic/"
Copy-Item "trashnet-master/dataset-resized/paper/*" "paper/"
Copy-Item "trashnet-master/dataset-resized/glass/*" "glass/"
Copy-Item "trashnet-master/dataset-resized/metal/*" "metal/"
Copy-Item "trashnet-master/dataset-resized/cardboard/*" "paper/"
Copy-Item "trashnet-master/dataset-resized/trash/*" "mixed/"
```

### 2. Create Organic Waste Samples

TrashNet doesn't include organic waste. You can:

**Option A**: Download from Kaggle
```
https://www.kaggle.com/datasets/sumn2u/garbage-classification-v2
```

**Option B**: Use placeholder images for testing
```powershell
# Create 10 placeholder images for organic category
1..10 | ForEach-Object {
    $null > "organic/sample_$_.jpg.txt"
}
```

**Option C**: Take your own photos
- Food scraps (banana peels, cassava peels, posho remains)
- Garden waste (leaves, grass clippings)
- Coffee grounds, tea bags

## Minimum Viable Dataset

For testing purposes, you need **at least 10 images per category**:

| Category | Minimum | Recommended | Source |
|----------|---------|-------------|--------|
| Plastic | 10 | 100+ | TrashNet |
| Organic | 10 | 100+ | Manual or Kaggle |
| Paper | 10 | 100+ | TrashNet |
| Glass | 10 | 50+ | TrashNet |
| Metal | 10 | 50+ | TrashNet |
| E-waste | 5 | 30+ | Manual photos |
| Hazardous | 5 | 30+ | Manual photos |
| Textile | 5 | 30+ | Manual photos |
| Mixed | 10 | 50+ | TrashNet (trash category) |

## Training Commands

### Train with default settings (200 estimators)
```powershell
python manage.py train_waste_classifier --data-dir apps/ai/training_data
```

### Train with custom settings
```powershell
python manage.py train_waste_classifier `
    --data-dir apps/ai/training_data `
    --n-estimators 500 `
    --output media/ai/waste_classifier_v2.joblib
```

### Expected Output
```
Found 1,245 training images across 8 categories
Training Random Forest classifier...
Class distribution:
  plastic: 312 samples
  paper: 285 samples
  organic: 198 samples
  glass: 152 samples
  metal: 128 samples
  mixed: 95 samples
  textile: 45 samples
  e-waste: 30 samples

Training complete!
Training accuracy: 87.3%
Model saved to: media/ai/waste_classifier.joblib
```

## Testing the Trained Model

```python
from apps.ai.classifier import classify_waste_image_bytes

# Test with a real image
with open('test_images/plastic_bottle.jpg', 'rb') as f:
    result = classify_waste_image_bytes(f.read())
    
print(f"Category: {result['category']}")
print(f"Confidence: {result['confidence']:.1%}")
print(f"Classifier: {result['classifier']}")
```

Expected:
```
Category: Plastic
Confidence: 92.3%
Classifier: random-forest-v1
```

## Pre-trained Model

A pre-trained model is **not included** in the repository because:
1. Model files are large (5-50MB depending on n_estimators)
2. Training data licensing may restrict redistribution
3. Models should be trained on Uganda-specific waste types

To deploy with a trained model:
1. Train locally with your dataset
2. Upload `waste_classifier.joblib` to your server
3. Set `AI_MODEL_PATH` environment variable or place in `MEDIA_ROOT/ai/`

## Fallback Behavior

If no trained model exists, the classifier automatically falls back to a **keyword-based heuristic**:
- Scans filename for keywords ("plastic", "bottle", "organic", etc.)
- Returns ~40% confidence
- Always provides a result (never fails)

This allows the app to work immediately without training data, while you collect real images for training.
