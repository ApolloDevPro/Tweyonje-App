from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import UUIDModel
from apps.profiles.models import Vehicle


class LiveLocation(UUIDModel):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="live_location",
    )
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="live_locations",
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    heading = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    speed_kmh = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    last_updated = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["-last_updated"]

    def __str__(self):
        return f"{self.user.email} @ ({self.latitude}, {self.longitude})"


class LocationHistory(UUIDModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="location_history",
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    recorded_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ["-recorded_at"]

    def __str__(self):
        return f"{self.user.email} history @ {self.recorded_at}"
