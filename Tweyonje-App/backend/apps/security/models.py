from django.conf import settings
from django.db import models
from django.utils import timezone
from datetime import timedelta

from core.models import UUIDModel


class AuditLog(UUIDModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="audit_logs",
    )
    action = models.CharField(max_length=255)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=512, blank=True)
    path = models.CharField(max_length=512, blank=True)
    method = models.CharField(max_length=16, blank=True)
    status_code = models.IntegerField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.action} by {self.user or 'Anonymous'} at {self.created_at}"


def default_reset_expiry():
    return timezone.now() + timedelta(hours=2)


class PasswordResetToken(UUIDModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="password_reset_tokens",
    )
    token = models.CharField(max_length=128, unique=True)
    expires_at = models.DateTimeField(default=default_reset_expiry)
    is_used = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Reset token for {self.user.email}"


class SecurityEvent(UUIDModel):
    class EventSeverity(models.TextChoices):
        LOW = "LOW", "Low"
        MEDIUM = "MEDIUM", "Medium"
        HIGH = "HIGH", "High"
        CRITICAL = "CRITICAL", "Critical"

    event_type = models.CharField(max_length=128)
    severity = models.CharField(max_length=32, choices=EventSeverity.choices, default=EventSeverity.LOW)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="security_events",
    )
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    description = models.TextField(blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"[{self.severity}] {self.event_type} - {self.created_at}"
