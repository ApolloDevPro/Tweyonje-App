"""
retry_failed_webhooks: Retry processing of failed webhook events.

This command finds webhook events that failed processing and retries them,
up to a maximum retry count.
"""
import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Retry processing of failed webhook events"

    def add_arguments(self, parser):
        parser.add_argument(
            '--max-retries',
            type=int,
            default=5,
            help='Maximum number of retries per event (default: 5)',
        )
        parser.add_argument(
            '--min-age-minutes',
            type=int,
            default=10,
            help='Only retry events older than this many minutes (default: 10)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Preview what would be retried without actually processing',
        )

    def handle(self, *args, **options):
        from apps.payments.models_webhook import WebhookEvent
        from apps.payments.services import apply_provider_callback
        
        max_retries = options['max_retries']
        min_age_minutes = options['min_age_minutes']
        dry_run = options['dry_run']
        
        # Find failed events that haven't exceeded max retries
        threshold = timezone.now() - timedelta(minutes=min_age_minutes)
        
        failed_events = WebhookEvent.objects.filter(
            status=WebhookEvent.Status.FAILED,
            retry_count__lt=max_retries,
            created_at__lt=threshold,
        ).order_by('created_at')
        
        total_count = failed_events.count()
        
        self.stdout.write(self.style.NOTICE(
            f"Found {total_count} failed webhook(s) to retry"
        ))
        
        if dry_run:
            for event in failed_events:
                self.stdout.write(
                    f"  [DRY RUN] Would retry: {event.provider} - {event.provider_reference} "
                    f"(retry {event.retry_count + 1}/{max_retries})"
                )
            return
        
        success_count = 0
        still_failing_count = 0
        
        for event in failed_events:
            try:
                self.stdout.write(
                    f"Retrying: {event.provider} - {event.provider_reference} "
                    f"(attempt {event.retry_count + 1})"
                )
                
                # Extract status from parsed data
                parsed = event.parsed_data
                status_value = str(parsed.get("status", "")).upper()
                transaction_id = parsed.get("financialTransactionId", "")
                
                # Attempt to process again
                payment = apply_provider_callback(
                    event.provider_reference,
                    status_value,
                    str(transaction_id)
                )
                
                if payment:
                    event.mark_processed(payment)
                    success_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(f"  ✓ Successfully processed")
                    )
                else:
                    event.mark_failed("Payment still not found")
                    still_failing_count += 1
                    self.stdout.write(
                        self.style.WARNING(f"  ⚠ Payment not found")
                    )
                    
            except Exception as exc:
                event.mark_failed(str(exc))
                still_failing_count += 1
                self.stdout.write(
                    self.style.ERROR(f"  ✗ Error: {exc}")
                )
        
        summary = (
            f"\nRetry complete:\n"
            f"  • {success_count} webhook(s) successfully processed\n"
            f"  • {still_failing_count} webhook(s) still failing\n"
            f"  • {total_count - success_count - still_failing_count} webhook(s) skipped"
        )
        
        if success_count > 0:
            self.stdout.write(self.style.SUCCESS(summary))
        elif still_failing_count > 0:
            self.stdout.write(self.style.WARNING(summary))
        else:
            self.stdout.write(summary)
