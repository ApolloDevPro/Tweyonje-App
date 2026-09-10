# AI Waste Classifier Training Data

This directory contains sample images for training the waste classification model.

## Dataset Structure

The dataset follows a **label-per-folder** format:

```
training_data/
├── plastic/
│   ├── plastic_bottle_001.jpg
│   ├── plastic_bag_002.jpg
│   └── ...
├── organic/
│   ├── food_waste_001.jpg
│   ├── banana_peel_002.jpg
│   └── ...
├── paper/
│   ├── cardboard_001.jpg
│   ├── newspaper_002.jpg
│   └── ...
├── glass/
│   ├── glass_bottle_001.jpg
│   └── ...
├── metal/
│   ├── aluminum_can_001.jpg
│   └── ...
├── e-waste/
│   ├── phone_001.jpg
│   └── ...
├── hazardous/
│   ├── battery_001.jpg
│   └── ...
└── textile/
    ├── clothing_001.jpg
    └── ...
```

## Folder Names (Must Match Slugs)

Each folder name must **exactly match** a slug from `apps/ai/categories.py`:

- `plastic`
- `organic`
- `paper`
- `glass`
- `metal`
- `e-waste`
- `hazardous`
- `textile`
- `mixed` (general waste)

## Image Requirements

- **Formats**: PNG, JPG, JPEG, WebP, BMP
- **Recommended**: At least 50-100 images per category for decent accuracy
- **Size**: Any size (the classifier downsamples to 64×64 during feature extraction)
- **Quality**: Clear photos of waste items in varied lighting/angles

## Training the Model

### From Django Management Command

```powershell
cd backend
python manage.py train_waste_classifier --data-dir apps/ai/training_data
```

### From Python Code

```python
from apps.ai.classifier import train_classifier

metrics = train_classifier(
    data_dir='apps/ai/training_data',
    n_estimators=200
)
print(metrics)
```

## Model Output

The trained model is saved to:
- **Location**: `MEDIA_ROOT/ai/waste_classifier.joblib` (default)
- **Override**: Set `AI_MODEL_PATH` in settings

## Collecting Real Training Data

### Option 1: User-Contributed Dataset

1. Add a "Report incorrect classification" button in the frontend
2. Store user corrections in a `ClassificationCorrection` model
3. Export corrections periodically:

```python
python manage.py export_classification_corrections --output corrections.csv
```

4. Download labeled images, reorganize into folders, and retrain

### Option 2: Public Datasets

- **TrashNet**: 2,527 images across 6 categories
  - https://github.com/garythung/trashnet
- **TACO (Trash Annotations in Context)**: 1,500+ images
  - http://tacodataset.org/
- **Waste Classification Data**: Kaggle datasets
  - https://www.kaggle.com/datasets/techsash/waste-classification-data

### Option 3: Manual Collection

Take photos of common waste items in Uganda:
- Plastic sachets (common in Uganda)
- Cassava peels (organic)
- Old jerrycans
- Waragi bottles (glass)
- Kavera bags (plastic)

## Model Performance

Current fallback heuristic: ~40% confidence (keyword matching)
Expected with 200+ images/category: **75-85% accuracy**

## Active Learning Loop

1. Deploy model
2. Log low-confidence predictions (<0.50)
3. Have admins manually label ambiguous cases
4. Add to training set
5. Retrain monthly

## Testing the Classifier

```python
from apps.ai.classifier import classify_waste_image_bytes

with open('test_image.jpg', 'rb') as f:
    result = classify_waste_image_bytes(f.read(), 'test_image.jpg')
    print(result)
```

Expected output:
```python
{
    'category': 'Plastic',
    'slug': 'plastic',
    'confidence': 0.8234,
    'recyclable': True,
    'instructions': 'Rinse and flatten bottles...',
    'estimated_value_ugx_kg': 500.0,
    'eco_points_potential_kg': 15.0,
    'classifier': 'random-forest-v1',
    'matched_filename': 'test_image.jpg'
}
```

## Future Enhancements

- [ ] CNN-based classifier with PyTorch (higher accuracy)
- [ ] Multi-label classification (images containing multiple waste types)
- [ ] Object detection with bounding boxes
- [ ] Mobile-optimized TFLite model for offline inference
