"""
backup_data: Dump database + media to a timestamped zip archive.
"""
import os
import zipfile
from datetime import datetime
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Backup database and media files to a zip archive"

    def add_arguments(self, parser):
        parser.add_argument("--output", type=str, default="backups", help="Output directory for backup files")

    def handle(self, *args, **kwargs):
        output_dir = kwargs["output"]
        os.makedirs(output_dir, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        zip_path = os.path.join(output_dir, f"backup_{timestamp}.zip")

        self.stdout.write(f"Creating backup at {zip_path}...")

        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            if os.path.exists("db.sqlite3"):
                zf.write("db.sqlite3")
                self.stdout.write("  - Added db.sqlite3")

            media_count = 0
            if os.path.exists("media"):
                for root, dirs, files in os.walk("media"):
                    for file in files:
                        file_path = os.path.join(root, file)
                        zf.write(file_path)
                        media_count += 1
                self.stdout.write(f"  - Added {media_count} media files")

        size_mb = os.path.getsize(zip_path) / 1024 / 1024
        self.stdout.write(self.style.SUCCESS(
            f"Backup complete: {zip_path} ({size_mb:.1f} MB)"
        ))
