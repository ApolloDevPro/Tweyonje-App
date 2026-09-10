from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import UUIDModel


class CollectorVerification(UUIDModel):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        APPROVED = "APPROVED", "Approved"
        REJECTED = "REJECTED", "Rejected"

    collector = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="verification",
    )
    national_id_number = models.CharField(max_length=64, blank=True)
    national_id_photo = models.ImageField(upload_to="verifications/", null=True, blank=True)
    driving_license_number = models.CharField(max_length=64, blank=True)
    driving_license_photo = models.ImageField(upload_to="verifications/", null=True, blank=True)
    vehicle_logbook_photo = models.ImageField(upload_to="verifications/", null=True, blank=True)
    background_check_passed = models.BooleanField(default=False)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_verifications",
    )
    reviewer_notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Verification for {self.collector.email} ({self.status})"


class PrivacyPolicy(UUIDModel):
    version = models.CharField(max_length=32, unique=True)
    title = models.CharField(max_length=255, default="Tweyonje Privacy Policy")
    content = models.TextField()
    is_active = models.BooleanField(default=False)
    published_at = models.DateTimeField(null=True, blank=True)
    published_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="published_policies",
    )

    class Meta:
        ordering = ["-published_at"]

    def __str__(self):
        return f"Policy {self.version} ({'Active' if self.is_active else 'Draft'})"


class PolicyConsent(UUIDModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="policy_consents",
    )
    policy = models.ForeignKey(
        PrivacyPolicy,
        on_delete=models.CASCADE,
        related_name="consents",
    )
    consented_at = models.DateTimeField(default=timezone.now)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        unique_together = ("user", "policy")
        ordering = ["-consented_at"]

    def __str__(self):
        return f"{self.user.email} consented {self.policy.version}"
