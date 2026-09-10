"""
train_waste_classifier: Train the scikit-learn waste image classifier.

Dataset layout: each subfolder of --data-dir must be named after a category
slug (plastic, organic, paper, glass, metal, e-waste) and contain image
files. Example::

    train_data/
        plastic/*.jpg
        organic/*.jpg
        paper/*.jpg
        glass/*.jpg
        metal/*.jpg
        e-waste/*.jpg

Without --data-dir the classifier is left in keyword-fallback mode and the
command reports the current model (if any).
"""
from django.core.management.base import BaseCommand, CommandError

from apps.ai import classifier


class Command(BaseCommand):
    help = "Train or inspect the AI waste image classifier"

    def add_arguments(self, parser):
        parser.add_argument(
            "--data-dir", type=str, default="", help="Path to label-per-folder training image directory"
        )
        parser.add_argument(
            "--epochs", type=int, default=10, help="Accepted for compatibility; used only for reporting"
        )
        parser.add_argument(
            "--n-estimators", type=int, default=200, help="Number of Random Forest trees"
        )

    def handle(self, *args, **kwargs):
        data_dir = kwargs["data_dir"]
        model_file = classifier.model_path()

        self.stdout.write("Waste Classifier Training")
        self.stdout.write(f"   Model output: {model_file}")
        self.stdout.write("")

        if not data_dir:
            exists = __import__("os").path.exists(model_file)
            if exists:
                self.stdout.write(self.style.SUCCESS("Trained model found; prediction uses it."))
                return
            self.stdout.write(self.style.WARNING(
                "No --data-dir provided and no trained model exists.\n"
                "Until trained, the classifier uses the deterministic keyword heuristic.\n"
                "Train it with:\n"
                "  python manage.py train_waste_classifier --data-dir path/to/train_data"
            ))
            return

        try:
            metrics = classifier.train_classifier(
                data_dir, epochs=kwargs["epochs"], n_estimators=kwargs["n_estimators"]
            )
        except ValueError as exc:
            raise CommandError(str(exc)) from exc
        except RuntimeError as exc:
            raise CommandError(str(exc)) from exc

        self.stdout.write(self.style.SUCCESS("Classifier training complete."))
        self.stdout.write(f"   Samples: {metrics['samples']}")
        self.stdout.write(f"   Classes: {', '.join(metrics['classes'])}")
        self.stdout.write(f"   Accuracy (train): {metrics['accuracy']:.3f}")
        for slug, count in metrics["class_distribution"].items():
            self.stdout.write(f"     {slug}: {count}")
        self.stdout.write(f"   Saved to: {metrics['model_path']}")