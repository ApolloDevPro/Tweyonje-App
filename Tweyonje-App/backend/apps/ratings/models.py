from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

from core.models import UUIDModel
from apps.waste_requests.models import WasteRequest


class Rating(UUIDModel):
    from_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ratings_given",
    )
    to_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ratings_received",
    )
    waste_request = models.ForeignKey(
        WasteRequest,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="ratings",
    )
    score = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="1 to 5 stars",
    )
    review = models.TextField(blank=True)
    is_public = models.BooleanField(default=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = ("from_user", "waste_request")

    def __str__(self):
        return f"{self.score}★ by {self.from_user.email} -> {self.to_user.email}"


class IncidentReport(UUIDModel):
    class Category(models.TextChoices):
        MISSED_COLLECTION = "MISSED_COLLECTION", "Missed Collection"
        PROPERTY_DAMAGE = "PROPERTY_DAMAGE", "Property Damage"
        UNPROFESSIONAL_BEHAVIOR = "UNPROFESSIONAL_BEHAVIOR", "Unprofessional Behavior"
        OVERCHARGING = "OVERCHARGING", "Overcharging / Illegal Fee"
        SPILLAGE = "SPILLAGE", "Waste Spillage"
        OTHER = "OTHER", "Other"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        INVESTIGATING = "INVESTIGATING", "Investigating"
        RESOLVED = "RESOLVED", "Resolved"
        DISMISSED = "DISMISSED", "Dismissed"

    reported_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="incidents_reported",
    )
    against_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="incidents_against",
    )
    waste_request = models.ForeignKey(
        WasteRequest,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="incidents",
    )
    category = models.CharField(max_length=32, choices=Category.choices, default=Category.OTHER)
    description = models.TextField()
    evidence_photo = models.ImageField(upload_to="incidents/", null=True, blank=True)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    resolution_notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Incident: {self.category} ({self.status})"


class UserSuspension(UUIDModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="suspensions",
    )
    reason = models.TextField()
    suspended_until = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    issued_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="issued_suspensions",
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Suspension for {self.user.email} ({'Active' if self.is_active else 'Expired'})"
