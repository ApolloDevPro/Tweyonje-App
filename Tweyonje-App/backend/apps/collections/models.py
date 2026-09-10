from django.conf import settings
from django.db import models

from core.models import UUIDModel, Zone
from apps.profiles.models import Vehicle
from apps.waste_requests.models import WasteRequest


class CollectionSlot(UUIDModel):
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name="collection_slots")
    weekday = models.IntegerField(help_text="0=Monday, 6=Sunday")
    start_time = models.TimeField()
    end_time = models.TimeField()
    max_capacity = models.PositiveIntegerField(default=20)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["weekday", "start_time"]
        unique_together = ("zone", "weekday", "start_time", "end_time")

    def __str__(self):
        weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        day_str = weekdays[self.weekday] if 0 <= self.weekday < 7 else str(self.weekday)
        return f"{self.zone.name} - {day_str} {self.start_time.strftime('%H:%M')}-{self.end_time.strftime('%H:%M')}"


class CollectionAssignment(UUIDModel):
    class Status(models.TextChoices):
        ASSIGNED = "ASSIGNED", "Assigned"
        EN_ROUTE = "EN_ROUTE", "En Route"
        ARRIVED = "ARRIVED", "Arrived"
        COLLECTED = "COLLECTED", "Collected"
        VERIFIED = "VERIFIED", "Verified"
        CANCELLED = "CANCELLED", "Cancelled"

    waste_request = models.ForeignKey(
        WasteRequest,
        on_delete=models.CASCADE,
        related_name="assignments",
    )
    collector = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="collection_assignments",
    )
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assignments",
    )
    status = models.CharField(
        max_length=32,
        choices=Status.choices,
        default=Status.ASSIGNED,
    )
    assigned_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    collected_weight_kg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-assigned_at"]

    def __str__(self):
        return f"Assignment: {self.waste_request.reference_id} -> {self.collector.email} ({self.status})"


class CollectorShift(UUIDModel):
    collector = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="shifts",
    )
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="shifts",
    )
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-started_at"]

    def __str__(self):
        return f"Shift for {self.collector.email} ({'Active' if self.is_active else 'Closed'})"
