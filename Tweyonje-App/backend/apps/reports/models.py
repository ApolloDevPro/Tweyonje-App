import random
import string
from django.conf import settings
from django.db import models

from core.models import UUIDModel, Zone


def _generate_report_ref():
    return f"TWY-RPT-{''.join(random.choices(string.ascii_uppercase + string.digits, k=8))}"


class IllegalDumpingReport(UUIDModel):
    class Severity(models.TextChoices):
        LOW = "LOW", "Low"
        MEDIUM = "MEDIUM", "Medium"
        HIGH = "HIGH", "High"
        CRITICAL = "CRITICAL", "Critical"

    class Status(models.TextChoices):
        SUBMITTED = "SUBMITTED", "Submitted"
        UNDER_INVESTIGATION = "UNDER_INVESTIGATION", "Under Investigation"
        SCHEDULED_CLEANUP = "SCHEDULED_CLEANUP", "Scheduled Cleanup"
        RESOLVED = "RESOLVED", "Resolved"
        DISMISSED = "DISMISSED", "Dismissed"

    reference_id = models.CharField(max_length=32, unique=True, default=_generate_report_ref, editable=False)
    reported_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="dumping_reports",
    )
    is_anonymous = models.BooleanField(default=False)
    address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    zone = models.ForeignKey(Zone, on_delete=models.SET_NULL, null=True, blank=True, related_name="dumping_reports")
    description = models.TextField()
    severity = models.CharField(max_length=32, choices=Severity.choices, default=Severity.MEDIUM)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.SUBMITTED)
    resolution_notes = models.TextField(blank=True)
    eco_points_awarded = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.reference_id} - {self.address} ({self.status})"


class ReportPhoto(UUIDModel):
    report = models.ForeignKey(
        IllegalDumpingReport,
        on_delete=models.CASCADE,
        related_name="photos",
    )
    photo = models.ImageField(upload_to="reports/")
    caption = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Photo for {self.report.reference_id}"
