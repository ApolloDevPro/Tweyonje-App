import random
import string
from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import UUIDModel
from apps.waste_requests.models import WasteRequest


def _generate_pay_ref():
    return f"TWY-PAY-{''.join(random.choices(string.ascii_uppercase + string.digits, k=10))}"


def _generate_payout_ref():
    return f"TWY-OUT-{''.join(random.choices(string.ascii_uppercase + string.digits, k=10))}"


def _generate_inv_ref():
    return f"INV-{''.join(random.choices(string.digits, k=8))}"


class Payment(UUIDModel):
    class Method(models.TextChoices):
        MTN_MOMO = "MTN_MOMO", "MTN Mobile Money"
        AIRTEL_MONEY = "AIRTEL_MONEY", "Airtel Money"
        CARD = "CARD", "Credit / Debit Card"
        CASH = "CASH", "Cash"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        SUCCESSFUL = "SUCCESSFUL", "Successful"
        FAILED = "FAILED", "Failed"
        REFUNDED = "REFUNDED", "Refunded"

    reference_id = models.CharField(max_length=32, unique=True, default=_generate_pay_ref, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payments",
    )
    waste_request = models.ForeignKey(
        WasteRequest,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=8, default="UGX")
    method = models.CharField(max_length=32, choices=Method.choices, default=Method.MTN_MOMO)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    phone_number = models.CharField(max_length=32, blank=True)
    transaction_id = models.CharField(max_length=128, blank=True)
    provider_reference = models.CharField(max_length=128, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.reference_id} - {self.amount} {self.currency} ({self.status})"


class Payout(UUIDModel):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        PROCESSED = "PROCESSED", "Processed"
        FAILED = "FAILED", "Failed"

    reference_id = models.CharField(max_length=32, unique=True, default=_generate_payout_ref, editable=False)
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payouts",
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=8, default="UGX")
    phone_number = models.CharField(max_length=32, blank=True)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    period_start = models.DateField(null=True, blank=True)
    period_end = models.DateField(null=True, blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Payout {self.reference_id} - {self.amount} {self.currency} to {self.recipient.email}"


class Invoice(UUIDModel):
    invoice_number = models.CharField(max_length=32, unique=True, default=_generate_inv_ref, editable=False)
    payment = models.OneToOneField(Payment, on_delete=models.CASCADE, related_name="invoice")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="invoices")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=8, default="UGX")
    items_json = models.JSONField(default=list, blank=True)
    issued_date = models.DateTimeField(default=timezone.now)
    is_paid = models.BooleanField(default=False)

    class Meta:
        ordering = ["-issued_date"]

    def __str__(self):
        return f"Invoice {self.invoice_number} ({self.amount} {self.currency})"


class Refund(UUIDModel):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        COMPLETED = "COMPLETED", "Completed"
        FAILED = "FAILED", "Failed"

    payment = models.ForeignKey(Payment, on_delete=models.CASCADE, related_name="refunds")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    reason = models.TextField()
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    processed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="processed_refunds",
    )
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Refund for {self.payment.reference_id} - {self.amount}"
