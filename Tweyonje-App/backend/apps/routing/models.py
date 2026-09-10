from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import UUIDModel


class RoutePlan(UUIDModel):
    class Status(models.TextChoices):
        DRAFT = "DRAFT", "Draft"
        OPTIMIZED = "OPTIMIZED", "Optimized"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COMPLETED = "COMPLETED", "Completed"

    collector = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="route_plans",
    )
    date = models.DateField(default=timezone.now)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.OPTIMIZED)
    total_distance_km = models.DecimalField(max_digits=8, decimal_places=2, default=0.0)
    estimated_duration_minutes = models.PositiveIntegerField(default=0)
    waypoints_order_json = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ["-date", "-created_at"]
        unique_together = ("collector", "date")

    def __str__(self):
        return f"Route for {self.collector.email} on {self.date} ({self.status})"
