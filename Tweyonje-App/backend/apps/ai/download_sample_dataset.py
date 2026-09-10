#!/usr/bin/env python
"""
Download and prepare the TrashNet sample dataset for training.

This script downloads the TrashNet dataset from GitHub and reorganizes it
into the format expected by the Tweyonje classifier.

Usage:
    python apps/ai/download_sample_dataset.py
"""
import os
import shutil
import urllib.request
import zipfile
from pathlib import Path


def download_trashnet(output_dir="apps/ai/training_data"):
    """Download TrashNet dataset and reorganize into training_data structure."""
    output_dir = Path(output_dir)
    temp_dir = Path("temp_trashnet")
    
    print("📦 Downloading TrashNet dataset...")
    zip_url = "https://github.com/garythung/trashnet/archive/master.zip"
    zip_path = "trashnet.zip"
    
    try:
        urllib.request.urlretrieve(zip_url, zip_path)
        print(f"✓ Downloaded {zip_path}")
    except Exception as e:
        print(f"✗ Failed to download: {e}")
        return False
    
    print("\n📂 Extracting dataset...")
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)
        print(f"✓ Extracted to {temp_dir}")
    except Exception as e:
        print(f"✗ Failed to extract: {e}")
        return False
    
    print("\n🔄 Reorganizing images...")
    
    # TrashNet categories → Tweyonje categories
    category_map = {
        "plastic": "plastic",
        "glass": "glass",
        "metal": "metal",
        "paper": "paper",
        "cardboard": "paper",  # Merge cardboard into paper
        "trash": "mixed",      # General waste
    }
    
    source_base = temp_dir / "trashnet-master" / "dataset-resized"
    
    if not source_base.exists():
        # Try alternate path
        source_base = temp_dir / "trashnet-master" / "data"
    
    if not source_base.exists():
        print(f"✗ Could not find dataset in {source_base}")
        print("   TrashNet structure may have changed.")
        return False
    
    stats = {}
    
    for source_cat, target_cat in category_map.items():
        source_folder = source_base / source_cat
        if not source_folder.exists():
            print(f"⚠ Skipping {source_cat} (not found)")
            continue
        
        target_folder = output_dir / target_cat
        target_folder.mkdir(parents=True, exist_ok=True)
        
        count = 0
        for img_file in source_folder.glob("*"):
            if img_file.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}:
                target_path = target_folder / f"trashnet_{source_cat}_{img_file.name}"
                shutil.copy2(img_file, target_path)
                count += 1
        
        stats[target_cat] = stats.get(target_cat, 0) + count
        print(f"  ✓ {source_cat} → {target_cat}: {count} images")
    
    print("\n🧹 Cleaning up...")
    shutil.rmtree(temp_dir)
    os.remove(zip_path)
    print("✓ Temporary files removed")
    
    print("\n📊 Dataset Summary:")
    print(f"{'Category':<15} {'Images':<10}")
    print("-" * 25)
    for cat, count in sorted(stats.items()):
        print(f"{cat:<15} {count:<10}")
    print("-" * 25)
    print(f"{'TOTAL':<15} {sum(stats.values()):<10}")
    
    print("\n✅ Dataset ready for training!")
    print("\nNext steps:")
    print("1. Add organic waste images to: apps/ai/training_data/organic/")
    print("2. Add e-waste images to: apps/ai/training_data/e-waste/")
    print("3. Add hazardous images to: apps/ai/training_data/hazardous/")
    print("4. Add textile images to: apps/ai/training_data/textile/")
    print("5. Run: python manage.py train_waste_classifier --data-dir apps/ai/training_data")
    
    return True


if __name__ == "__main__":
    import sys
    
    print("=" * 60)
    print("TrashNet Dataset Downloader for Tweyonje")
    print("=" * 60)
    print()
    
    success = download_trashnet()
    sys.exit(0 if success else 1)
