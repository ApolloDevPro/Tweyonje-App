from datetime import timedelta
import hashlib
import secrets
import string

from django.conf import settings
from django.db import models
from django.utils import timezone
from django.utils.crypto import constant_time_compare

from core.models import UUIDModel


def default_otp_expiry():
    return timezone.now() + timedelta(minutes=10)


def generate_otp_code():
    return "".join(secrets.choice(string.digits) for _ in range(6))


def hash_otp_code(code):
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


class OTPVerification(UUIDModel):
    class Purpose(models.TextChoices):
        REGISTRATION = "REGISTRATION", "Registration"
        PHONE_VERIFY = "PHONE_VERIFY", "Phone Verification"
        EMAIL_VERIFY = "EMAIL_VERIFY", "Email Verification"
        PASSWORD_RESET = "PASSWORD_RESET", "Password Reset"
        LOGIN_2FA = "LOGIN_2FA", "Login 2FA"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="otp_verifications",
    )
    identifier = models.CharField(max_length=255)  # phone number or email address
    # Stores only a SHA-256 hash of the OTP; the plaintext code is never persisted.
    otp_code = models.CharField(max_length=64, blank=True)
    purpose = models.CharField(max_length=32, choices=Purpose.choices, default=Purpose.PHONE_VERIFY)
    is_verified = models.BooleanField(default=False)
    expires_at = models.DateTimeField(default=default_otp_expiry)
    attempts = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-created_at"]

    def is_valid(self):
        return not self.is_verified and self.expires_at > timezone.now() and self.attempts < 5

    def check_code(self, code) -> bool:
        """Compare a submitted code against the stored hash."""
        return constant_time_compare(self.otp_code, hash_otp_code((code or "").strip()))

    def __str__(self):
        return f"OTP for {self.identifier} ({self.purpose})"
