"""
retry_notifications: Redeliver failed notifications with exponential backoff.
"""
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Retry failed notifications (SMS, Email, Push) with backoff"

    def add_arguments(self, parser):
        parser.add_argument("--max-retries", type=int, default=3, help="Max retry attempts per notification")

    def handle(self, *args, **kwargs):
        from apps.notifications.services import retry_failed_notifications
        max_retries = kwargs["max_retries"]
        self.stdout.write(f"Retrying failed notifications (max_retries={max_retries})...")
        retried = retry_failed_notifications(max_retries=max_retries)
        self.stdout.write(self.style.SUCCESS(f"Successfully retried {retried} notifications."))
