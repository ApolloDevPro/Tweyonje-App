"""Periodic tasks wrapping the existing management commands.

These run under Celery Beat (see CELERY_BEAT_SCHEDULE in settings) and
delegate to the battle-tested command implementations.
"""

from __future__ import annotations

import logging

from celery import shared_task
from django.core.management import call_command

logger = logging.getLogger(__name__)


def _run_command(name: str, *args, **options) -> str:
    try:
        call_command(name, *args, **options)
        return "ok"
    except Exception:
        logger.exception("Scheduled task %s failed", name)
        raise


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def process_due_schedules(self):
    return _run_command("process_due_schedules")


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def check_sla(self):
    return _run_command("check_sla")


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def retry_notifications(self):
    return _run_command("retry_notifications")


@shared_task(bind=True, max_retries=2, default_retry_delay=300)
def run_payouts(self, period_start=None, period_end=None):
    return _run_command(
        "run_payouts",
        **({"period_start": period_start} if period_start else {}),
        **({"period_end": period_end} if period_end else {}),
    )


@shared_task(bind=True, max_retries=2, default_retry_delay=300)
def run_reconciliation(self):
    return _run_command("run_reconciliation")


@shared_task(bind=True, max_retries=3, default_retry_delay=30)
def poll_payment_status(self, payment_id: str):
    """Poll the provider for a pending mobile-money transaction."""
    from apps.payments.models import Payment
    from apps.payments.services import sync_payment_status

    payment = Payment.objects.filter(id=payment_id).first()
    if not payment or payment.status != Payment.Status.PENDING:
        return "skipped"
    sync_payment_status(payment)
    return payment.status
