import uuid

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from .managers import UserManager


class Role(models.TextChoices):
    RESIDENT = "RESIDENT", "Resident"
    BUSINESS = "BUSINESS", "Business"
    COLLECTOR = "COLLECTOR", "Collector"
    RECYCLER = "RECYCLER", "Recycler"
    AUTHORITY = "AUTHORITY", "Authority"
    ADMINISTRATOR = "ADMINISTRATOR", "Administrator"


class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255, blank=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    phone = models.CharField(max_length=32, blank=True, null=True)
    role = models.CharField(max_length=32, choices=Role.choices, default=Role.RESIDENT)
    preferred_language = models.CharField(max_length=8, default="en")
    phone_verified = models.BooleanField(default=False)
    email_verified = models.BooleanField(default=False)  
    consent_policy_version = models.CharField(max_length=64, blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    class Meta:
        ordering = ["-date_joined"]

    def __str__(self):
        return self.email

    @property
    def display_name(self):
        return self.full_name or f"{self.first_name} {self.last_name}".strip() or self.email

    def award_role(self, role):
        self.role = role
        self.save(update_fields=["role", "updated_at"])


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class UUIDModel(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    class Meta:
        abstract = True


class Zone(UUIDModel):
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=32, unique=True)
    region = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class SystemSetting(models.Model):
    key = models.CharField(max_length=128, unique=True)
    value = models.TextField()
    description = models.CharField(max_length=512, blank=True)

    class Meta:
        ordering = ["key"]

    def __str__(self):
        return self.key
