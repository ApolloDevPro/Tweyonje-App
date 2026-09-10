"""
run_reconciliation: Reconcile payment provider statements vs platform records.

This command:
1. Polls MTN/Airtel for pending payment statuses
2. Marks truly stale payments as FAILED after threshold
3. Logs all reconciliation actions for audit trail
"""
import logging
from django.core.management.base import BaseCommand

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Reconcile payment transactions against provider records"

    def add_arguments(self, parser):
        parser.add_argument(
            '--stale-hours',
            type=int,
            default=None,
            help='Override RECONCILIATION_STALE_HOURS setting',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Preview changes without committing them',
        )

    def handle(self, *args, **options):
        from datetime import timedelta
        from django.conf import settings
        from django.utils import timezone
        from apps.payments.models import Payment
        from apps.payments.services import sync_payment_status, _fail_linked_request

        dry_run = options['dry_run']
        stale_hours = options['stale_hours'] or getattr(settings, "RECONCILIATION_STALE_HOURS", 8)
        threshold = timezone.now() - timedelta(hours=stale_hours)

        stale_pending = Payment.objects.filter(
            status=Payment.Status.PENDING,
            created_at__lt=threshold,
        )
        
        # Only payments with provider_reference can be reconciled with provider
        stale_live = stale_pending.filter(provider_reference__gt="")
        
        self.stdout.write(self.style.NOTICE(
            f"Found {stale_live.count()} stale pending payments (older than {stale_hours}h)"
        ))

        synced_count = 0
        failed_count = 0
        skipped_count = 0

        for payment in stale_live:
            try:
                # First, try to sync with provider
                if not dry_run:
                    previous_status = payment.status
                    sync_payment_status(payment)
                    payment.refresh_from_db()
                    
                    if payment.status != previous_status:
                        synced_count += 1
                        self.stdout.write(
                            f"  ✓ {payment.reference_id}: synced from provider → {payment.status}"
                        )
                        continue

                # If still PENDING after sync, mark as FAILED
                if payment.status == Payment.Status.PENDING:
                    if not dry_run:
                        payment.status = Payment.Status.FAILED
                        payment.metadata["reconciled"] = True
                        payment.metadata["reconciliation_timestamp"] = timezone.now().isoformat()
                        payment.metadata["reconciliation_note"] = (
                            f"No provider confirmation after {stale_hours}h; marked FAILED by reconciliation."
                        )
                        payment.save(update_fields=["status", "metadata", "updated_at"])
                        _fail_linked_request(payment)
                        failed_count += 1
                        self.stdout.write(
                            self.style.WARNING(f"  ⚠ {payment.reference_id}: marked FAILED (no provider response)")
                        )
                    else:
                        self.stdout.write(
                            self.style.WARNING(f"  [DRY RUN] Would mark {payment.reference_id} as FAILED")
                        )
                        failed_count += 1
                        
            except Exception as exc:
                logger.exception(f"Reconciliation failed for payment {payment.id}")
                skipped_count += 1
                self.stdout.write(
                    self.style.ERROR(f"  ✗ {payment.reference_id}: error - {exc}")
                )

        untouched = stale_pending.count() - stale_live.count()
        
        summary = (
            f"\n{'[DRY RUN] ' if dry_run else ''}Reconciliation complete:\n"
            f"  • {synced_count} payments synced from provider\n"
            f"  • {failed_count} payments marked FAILED\n"
            f"  • {skipped_count} payments skipped (errors)\n"
            f"  • {untouched} dev-mode payments left unchanged"
        )
        self.stdout.write(self.style.SUCCESS(summary))