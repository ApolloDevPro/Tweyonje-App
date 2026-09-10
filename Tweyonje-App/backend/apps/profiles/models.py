from django.conf import settings
from django.db import models

from core.models import Role, TimeStampedModel, UUIDModel, Zone


class Profile(UUIDModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="profile")
    role = models.CharField(max_length=32, choices=Role.choices, editable=False)
    bio = models.TextField(blank=True)
    address = models.CharField(max_length=512, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    avatar = models.ImageField(upload_to="avatars/", null=True, blank=True)
    zone = models.ForeignKey(Zone, on_delete=models.SET_NULL, null=True, blank=True, related_name="profiles")

    def save(self, *args, **kwargs):
        self.role = self.user.role
        super().save(*args, **kwargs)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} profile"


class Vehicle(UUIDModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="vehicles")
    plate_number = models.CharField(max_length=32)
    vehicle_type = models.CharField(max_length=64, blank=True)
    capacity_kg = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    is_default = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.plate_number


class Site(UUIDModel):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="sites")
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=512, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    zone = models.ForeignKey(Zone, on_delete=models.SET_NULL, null=True, blank=True, related_name="sites")
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class NotificationPreference(UUIDModel):
    CHANNELS = (
        ("PUSH", "Push"),
        ("EMAIL", "Email"),
        ("SMS", "SMS"),
    )
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notification_prefs")
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=True)
    quiet_hours_start = models.TimeField(null=True, blank=True)
    quiet_hours_end = models.TimeField(null=True, blank=True)
    categories = models.JSONField(default=list, blank=True)

    class Meta:
        verbose_name = "notification preference"

    def __str__(self):
        return f"{self.user.email} prefs"
