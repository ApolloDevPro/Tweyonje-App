import logging
import uuid
from django.utils import timezone
from django.conf import settings

from apps.waste_requests.models import WasteRequest
from .models import Invoice, Payment, Payout, Refund

logger = logging.getLogger(__name__)

PENDING_POLL_DELAYS = (15, 30, 60)  # seconds between status polls


def _finalize_successful_payment(payment: Payment) -> Payment:
    """Mark a payment successful and cascade side effects."""
    payment.status = Payment.Status.SUCCESSFUL
    if not payment.transaction_id:
        payment.transaction_id = f"TXN-{uuid.uuid4().hex[:10].upper()}"
    payment.save(update_fields=["status", "transaction_id", "updated_at"])

    if payment.waste_request_id:
        request = payment.waste_request
        request.payment_status = WasteRequest.PaymentStatus.PAID
        request.paid_amount = payment.amount
        request.save(update_fields=["payment_status", "paid_amount", "updated_at"])

    if not hasattr(payment, "invoice"):
        Invoice.objects.create(
            payment=payment,
            user=payment.user,
            amount=payment.amount,
            currency=payment.currency,
            items_json=[{
                "description": (
                    f"Waste Collection ({payment.waste_request.reference_id})"
                    if payment.waste_request else "General"
                ),
                "amount": float(payment.amount),
            }],
            is_paid=True,
        )
    return payment


def _initiate_via_provider(payment: Payment) -> Payment:
    """Submit a PENDING payment to the configured live provider."""
    provider_name = getattr(settings, "PAYMENT_PROVIDER", "dev")
    callback_url = getattr(settings, "MTN_MOMO_CALLBACK_URL" if provider_name == "mtn" else "AIRTEL_CALLBACK_URL", "")

    try:
        if provider_name == "mtn":
            from .providers.mtn_momo import MTNMoMoClient

            client = MTNMoMoClient()
            reference = client.request_to_pay(
                amount=payment.amount,
                currency=payment.currency,
                payer_phone=payment.phone_number,
                external_id=payment.reference_id,
                callback_url=callback_url or None,
            )
            payment.provider_reference = reference
        elif provider_name == "airtel":
            from .providers.airtel_money import AirtelMoneyClient

            client = AirtelMoneyClient()
            result = client.initiate_collection(
                amount=payment.amount,
                currency=payment.currency,
                payer_phone=payment.phone_number.lstrip("+"),
                external_id=payment.reference_id,
            )
            payment.provider_reference = result["transaction_id"] or payment.provider_reference
            payment.metadata["provider_status"] = result["raw_status"]
            if result.get("status") == "SUCCESSFUL":
                return _finalize_successful_payment(payment)
        else:
            raise ValueError(f"Unknown PAYMENT_PROVIDER '{provider_name}'")
    except Exception as exc:
        logger.exception("Provider initiation failed for %s", payment.reference_id)
        payment.status = Payment.Status.FAILED
        payment.metadata["provider_error"] = str(exc)[:500]
        payment.save(update_fields=["status", "metadata", "updated_at"])
        return payment

    payment.save(update_fields=["provider_reference", "metadata", "updated_at"])
    _schedule_status_poll(payment)
    return payment


def _schedule_status_poll(payment: Payment) -> None:
    try:
        from config.celery import app as celery_app

        for index, delay in enumerate(PENDING_POLL_DELAYS):
            celery_app.send_task(
                "core.tasks.poll_payment_status",
                args=[str(payment.id)],
                countdown=delay * (index + 1),
            )
    except Exception:
        logger.warning("Celery unavailable; payment %s will rely on webhooks only.", payment.reference_id)


def initiate_momo_payment(user, waste_request, phone, method=Payment.Method.MTN_MOMO, amount=None):
    if not amount:
        amount = waste_request.estimated_price if waste_request else 5000.0

    payment = Payment.objects.create(
        user=user,
        waste_request=waste_request,
        amount=amount,
        currency=getattr(settings, "CURRENCY", "UGX"),
        method=method,
        phone_number=phone or user.phone or "",
        status=Payment.Status.PENDING,
        provider_reference=f"MOMO-{uuid.uuid4().hex[:12].upper()}",
    )

    # If in development or demo mode, simulate success instantly
    provider = getattr(settings, "PAYMENT_PROVIDER", "dev")
    if provider == "dev":
        return _finalize_successful_payment(payment)

    if method in (Payment.Method.MTN_MOMO, Payment.Method.AIRTEL_MONEY):
        return _initiate_via_provider(payment)

    # Non-mobile-money methods have no provider integration yet.
    return payment


def sync_payment_status(payment: Payment) -> Payment:
    """Ask the provider for the current state of a pending transaction."""
    if payment.status != Payment.Status.PENDING:
        return payment

    provider = getattr(settings, "PAYMENT_PROVIDER", "dev")
    try:
        if provider == "mtn":
            from .providers.mtn_momo import MTNMoMoClient

            result = MTNMoMoClient().get_transaction_status(payment.provider_reference)
        elif provider == "airtel":
            from .providers.airtel_money import AirtelMoneyClient

            reference = payment.provider_reference or payment.transaction_id
            result = AirtelMoneyClient().get_transaction_status(reference)
        else:
            return payment
    except Exception as exc:
        logger.exception("Status poll failed for %s", payment.reference_id)
        payment.metadata["last_poll_error"] = str(exc)[:300]
        payment.save(update_fields=["metadata", "updated_at"])
        return payment

    payment.metadata["provider_status"] = result["raw_status"]
    if result.get("reason"):
        payment.metadata["provider_reason"] = str(result["reason"])[:300]
    if result["status"] == "SUCCESSFUL":
        payment.transaction_id = result.get("transaction_id") or payment.transaction_id
        return _finalize_successful_payment(payment)
    if result["status"] == "FAILED":
        payment.status = Payment.Status.FAILED
        payment.save(update_fields=["status", "metadata", "updated_at"])
        _fail_linked_request(payment)
        return payment

    payment.save(update_fields=["metadata", "updated_at"])
    return payment


def apply_provider_callback(reference: str, status_value: str, transaction_id: str = "") -> Payment | None:
    """Update a payment from a provider webhook/callback payload."""
    from django.db import models as dj_models

    payment = Payment.objects.filter(
        dj_models.Q(provider_reference=reference) | dj_models.Q(reference_id=reference)
    ).first()
    if not payment:
        return None

    normalized = status_value.upper()
    if normalized in ("SUCCESSFUL", "SUCCESS"):
        if transaction_id:
            payment.transaction_id = transaction_id
        _finalize_successful_payment(payment)
    elif normalized in ("FAILED", "FAILURE"):
        payment.status = Payment.Status.FAILED
        payment.save(update_fields=["status", "updated_at"])
        _fail_linked_request(payment)
    else:
        payment.metadata["provider_status"] = normalized
        payment.save(update_fields=["metadata", "updated_at"])
    return payment


def _fail_linked_request(payment: Payment) -> None:
    if not payment.waste_request_id:
        return
    request = payment.waste_request
    if request.payment_status == WasteRequest.PaymentStatus.PAID and payment.status == Payment.Status.FAILED:
        request.payment_status = WasteRequest.PaymentStatus.UNPAID
        request.save(update_fields=["payment_status", "updated_at"])


def create_refund_for_request(waste_request, reason="Dispute resolution refund", admin_user=None):
    payment = Payment.objects.filter(
        waste_request=waste_request,
        status=Payment.Status.SUCCESSFUL,
    ).first()

    if not payment:
        return None

    refund = Refund.objects.create(
        payment=payment,
        amount=payment.amount,
        reason=reason,
        status=Refund.Status.COMPLETED,
        processed_by=admin_user,
        processed_at=timezone.now(),
    )
    payment.status = Payment.Status.REFUNDED
    payment.save(update_fields=["status", "updated_at"])

    waste_request.payment_status = WasteRequest.PaymentStatus.REFUNDED
    waste_request.save(update_fields=["payment_status", "updated_at"])

    return refund


def batch_process_payouts(period_start=None, period_end=None):
    from django.contrib.auth import get_user_model
    from core.models import Role

    User = get_user_model()
    collectors = User.objects.filter(role=Role.COLLECTOR, is_active=True)
    created_payouts = []

    for collector in collectors:
        # Idempotency guard: never create a second payout for the same
        # collector + period while a payout is already pending/processed.
        already_processed = Payout.objects.filter(
            recipient=collector,
            status__in=[Payout.Status.PENDING, Payout.Status.PROCESSED],
            period_start=period_start,
            period_end=period_end,
        ).exists()
        if already_processed:
            continue

        # Sum completed jobs payout share (e.g. 70% of collection fees)
        assignments = collector.collection_assignments.filter(
            status="COLLECTED",
        )
        if period_start:
            assignments = assignments.filter(completed_at__date__gte=period_start)
        if period_end:
            assignments = assignments.filter(completed_at__date__lte=period_end)

        total_collected_amount = sum(
            float(a.waste_request.paid_amount or 0) for a in assignments if a.waste_request
        )

        payout_amount = total_collected_amount * 0.70  # 70% share to collector
        if payout_amount > 0:
            # Created as PENDING: actual disbursement is performed separately
            # once a payment provider is reached. Never auto-mark PROCESSED.
            payout = Payout.objects.create(
                recipient=collector,
                amount=payout_amount,
                currency="UGX",
                phone_number=collector.phone or "",
                status=Payout.Status.PENDING,
                period_start=period_start,
                period_end=period_end,
                notes=f"Batch payout for {assignments.count()} collections",
            )
            created_payouts.append(payout)

    return created_payouts
