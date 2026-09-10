import random
import string
from datetime import timedelta
from django.conf import settings
from django.db import models
from django.utils import timezone

from core.models import UUIDModel
from apps.waste_requests.models import WasteRequest


def _generate_ticket_ref():
    return f"TCK-{''.join(random.choices(string.digits, k=6))}"


def _generate_dispute_ref():
    return f"DSP-{''.join(random.choices(string.digits, k=6))}"


def default_sla_deadline():
    return timezone.now() + timedelta(hours=24)


class SupportTicket(UUIDModel):
    class Category(models.TextChoices):
        COLLECTION_ISSUE = "COLLECTION_ISSUE", "Collection Issue"
        PAYMENT_ISSUE = "PAYMENT_ISSUE", "Payment & Billing"
        APP_BUG = "APP_BUG", "App Bug / Technical Problem"
        RECYCLING_INQUIRY = "RECYCLING_INQUIRY", "Recycling & Trade-in"
        OTHER = "OTHER", "General Inquiry"

    class Priority(models.TextChoices):
        LOW = "LOW", "Low"
        MEDIUM = "MEDIUM", "Medium"
        HIGH = "HIGH", "High"
        URGENT = "URGENT", "Urgent"

    class Status(models.TextChoices):
        OPEN = "OPEN", "Open"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        RESOLVED = "RESOLVED", "Resolved"
        CLOSED = "CLOSED", "Closed"

    ticket_number = models.CharField(max_length=32, unique=True, default=_generate_ticket_ref, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="support_tickets",
    )
    subject = models.CharField(max_length=255)
    category = models.CharField(max_length=32, choices=Category.choices, default=Category.OTHER)
    priority = models.CharField(max_length=32, choices=Priority.choices, default=Priority.MEDIUM)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.OPEN)
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_tickets",
    )
    sla_deadline = models.DateTimeField(default=default_sla_deadline)
    is_escalated = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.ticket_number}: {self.subject} ({self.status})"


class TicketMessage(UUIDModel):
    ticket = models.ForeignKey(
        SupportTicket,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ticket_messages",
    )
    message = models.TextField()
    attachment = models.FileField(upload_to="support_attachments/", null=True, blank=True)
    is_internal = models.BooleanField(default=False)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Msg on {self.ticket.ticket_number} by {self.sender.email}"


class Dispute(UUIDModel):
    class Resolution(models.TextChoices):
        PENDING = "PENDING", "Pending Review"
        RESOLVED_NO_ACTION = "RESOLVED_NO_ACTION", "Resolved (No Action)"
        REFUND_RESIDENT = "REFUND_RESIDENT", "Refund Resident"
        REASSIGN_COLLECTOR = "REASSIGN_COLLECTOR", "Reassign Collector"
        DISMISSED = "DISMISSED", "Dismissed"

    reference_id = models.CharField(max_length=32, unique=True, default=_generate_dispute_ref, editable=False)
    waste_request = models.ForeignKey(
        WasteRequest,
        on_delete=models.CASCADE,
        related_name="disputes",
    )
    raised_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="disputes_raised",
    )
    reason = models.TextField()
    evidence_photo = models.ImageField(upload_to="dispute_evidence/", null=True, blank=True)
    resolution = models.CharField(max_length=32, choices=Resolution.choices, default=Resolution.PENDING)
    resolution_notes = models.TextField(blank=True)
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="resolved_disputes",
    )
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.reference_id} on {self.waste_request.reference_id} ({self.resolution})"
