import random
import string
from decimal import Decimal

from django.conf import settings
from django.db import models

from core.models import UUIDModel, Zone


def _generate_req_ref():
    return f"TWY-REQ-{''.join(random.choices(string.ascii_uppercase + string.digits, k=8))}"


class WasteCategory(UUIDModel):
    name = models.CharField(max_length=128)
    slug = models.SlugField(max_length=128, unique=True)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=64, blank=True, default="trash")
    is_hazardous = models.BooleanField(default=False)
    default_price_per_kg = models.DecimalField(max_digits=10, decimal_places=2, default=500.00)
    base_eco_points = models.PositiveIntegerField(default=10)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Waste categories"
        ordering = ["name"]

    def __str__(self):
        return self.name


class RecurringSchedule(UUIDModel):
    class Frequency(models.TextChoices):
        DAILY = "DAILY", "Daily"
        WEEKLY = "WEEKLY", "Weekly"
        BI_WEEKLY = "BI_WEEKLY", "Bi-Weekly"
        MONTHLY = "MONTHLY", "Monthly"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="schedules")
    category = models.ForeignKey(WasteCategory, on_delete=models.CASCADE, related_name="schedules")
    frequency = models.CharField(max_length=32, choices=Frequency.choices, default=Frequency.WEEKLY)
    preferred_weekday = models.IntegerField(default=0)  # 0=Monday, 6=Sunday
    preferred_time = models.TimeField(null=True, blank=True)
    address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    zone = models.ForeignKey(Zone, on_delete=models.SET_NULL, null=True, blank=True, related_name="schedules")
    is_active = models.BooleanField(default=True)
    last_generated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.frequency} ({self.category.name})"


class WasteRequest(UUIDModel):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        SCHEDULED = "SCHEDULED", "Scheduled"
        ASSIGNED = "ASSIGNED", "Assigned"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COLLECTED = "COLLECTED", "Collected"
        CANCELLED = "CANCELLED", "Cancelled"
        REJECTED = "REJECTED", "Rejected"

    class PaymentStatus(models.TextChoices):
        UNPAID = "UNPAID", "Unpaid"
        PENDING = "PENDING", "Pending"
        PAID = "PAID", "Paid"
        REFUNDED = "REFUNDED", "Refunded"

    reference_id = models.CharField(max_length=32, unique=True, default=_generate_req_ref, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="waste_requests")
    category = models.ForeignKey(WasteCategory, on_delete=models.CASCADE, related_name="requests")
    schedule = models.ForeignKey(RecurringSchedule, on_delete=models.SET_NULL, null=True, blank=True, related_name="generated_requests")
    estimated_weight_kg = models.DecimalField(max_digits=8, decimal_places=2, default=5.0)
    actual_weight_kg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    pickup_address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    zone = models.ForeignKey(Zone, on_delete=models.SET_NULL, null=True, blank=True, related_name="waste_requests")
    scheduled_date = models.DateField(null=True, blank=True)
    scheduled_time_slot = models.CharField(max_length=64, blank=True)
    special_instructions = models.TextField(blank=True)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    is_emergency = models.BooleanField(default=False)
    estimated_price = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    payment_status = models.CharField(max_length=32, choices=PaymentStatus.choices, default=PaymentStatus.UNPAID)
    eco_points_awarded = models.PositiveIntegerField(default=0)
    cancellation_reason = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        if not self.estimated_price and self.category:
            self.estimated_price = self.estimated_weight_kg * self.category.default_price_per_kg
            if self.is_emergency:
                self.estimated_price *= Decimal("1.5")
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.reference_id} - {self.category.name} ({self.status})"


class WasteRequestPhoto(UUIDModel):
    class PhotoType(models.TextChoices):
        BEFORE_PICKUP = "BEFORE_PICKUP", "Before Pickup"
        AFTER_PICKUP = "AFTER_PICKUP", "After Pickup"
        RECEIPT = "RECEIPT", "Receipt"

    waste_request = models.ForeignKey(WasteRequest, on_delete=models.CASCADE, related_name="photos")
    photo = models.ImageField(upload_to="waste_requests/")
    caption = models.CharField(max_length=255, blank=True)
    photo_type = models.CharField(max_length=32, choices=PhotoType.choices, default=PhotoType.BEFORE_PICKUP)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Photo for {self.waste_request.reference_id}"
