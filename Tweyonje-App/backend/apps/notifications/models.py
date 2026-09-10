from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import UUIDModel


class NotificationDevice(UUIDModel):
    """A registered device capable of receiving push notifications."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_devices",
    )
    token = models.CharField(max_length=512)
    device_type = models.CharField(max_length=32, default="mobile")
    is_active = models.BooleanField(default=True)
    last_seen_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "token"], name="unique_device_token_per_user")
        ]
        ordering = ["-last_seen_at"]

    def __str__(self):
        return f"{self.user.email} ({self.device_type})"


class Notification(UUIDModel):
    class Channel(models.TextChoices):
        IN_APP = "IN_APP", "In-App"
        PUSH = "PUSH", "Push Notification"
        SMS = "SMS", "SMS"
        EMAIL = "EMAIL", "Email"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        SENT = "SENT", "Sent"
        FAILED = "FAILED", "Failed"

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    channel = models.CharField(max_length=32, choices=Channel.choices, default=Channel.IN_APP)
    is_read = models.BooleanField(default=False)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    failure_reason = models.TextField(blank=True)
    retry_count = models.PositiveIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"[{self.channel}] {self.title} -> {self.recipient.email}"
