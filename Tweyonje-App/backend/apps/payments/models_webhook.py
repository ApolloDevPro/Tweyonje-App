"""Webhook event logging for payment provider callbacks."""
from django.db import models
from core.models import UUIDModel


class WebhookEvent(UUIDModel):
    """
    Log of all incoming webhook events from payment providers.
    
    Provides:
    - Audit trail of all callbacks
    - Idempotency (prevent double-processing)
    - Retry mechanism for failed webhooks
    """
    
    class Provider(models.TextChoices):
        MTN_MOMO = "MTN_MOMO", "MTN Mobile Money"
        AIRTEL_MONEY = "AIRTEL_MONEY", "Airtel Money"
        CARD = "CARD", "Card Payment"
        OTHER = "OTHER", "Other Provider"
    
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        PROCESSED = "PROCESSED", "Processed"
        FAILED = "FAILED", "Failed"
        DUPLICATE = "DUPLICATE", "Duplicate"
    
    # Identification
    provider = models.CharField(max_length=20, choices=Provider.choices)
    provider_reference = models.CharField(
        max_length=255,
        db_index=True,
        help_text="Reference ID from the provider (e.g., MTN transaction ID)"
    )
    idempotency_key = models.CharField(
        max_length=255,
        unique=True,
        db_index=True,
        help_text="Unique key to prevent duplicate processing"
    )
    
    # Request details
    http_method = models.CharField(max_length=10, default="POST")
    remote_ip = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    raw_headers = models.JSONField(default=dict, blank=True)
    raw_body = models.TextField(help_text="Raw request body for audit")
    parsed_data = models.JSONField(
        default=dict,
        blank=True,
        help_text="Parsed JSON payload"
    )
    
    # Processing
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True
    )
    processed_at = models.DateTimeField(null=True, blank=True)
    payment = models.ForeignKey(
        "payments.Payment",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="webhook_events"
    )
    
    # Error handling
    error_message = models.TextField(blank=True)
    retry_count = models.PositiveIntegerField(default=0)
    last_retry_at = models.DateTimeField(null=True, blank=True)
    
    # Security
    signature_verified = models.BooleanField(default=False)
    signature_value = models.TextField(blank=True)
    
    class Meta:
        db_table = "payment_webhook_events"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["provider", "status"]),
            models.Index(fields=["created_at"]),
            models.Index(fields=["provider_reference"]),
        ]
    
    def __str__(self):
        return f"Webhook {self.provider} - {self.provider_reference} ({self.status})"
    
    def mark_processed(self, payment):
        """Mark webhook as successfully processed."""
        from django.utils import timezone
        
        self.status = self.Status.PROCESSED
        self.processed_at = timezone.now()
        self.payment = payment
        self.save(update_fields=["status", "processed_at", "payment", "updated_at"])
    
    def mark_failed(self, error_message):
        """Mark webhook as failed."""
        from django.utils import timezone
        
        self.status = self.Status.FAILED
        self.error_message = error_message
        self.last_retry_at = timezone.now()
        self.retry_count += 1
        self.save(update_fields=["status", "error_message", "retry_count", "last_retry_at", "updated_at"])
    
    def mark_duplicate(self):
        """Mark webhook as duplicate (already processed)."""
        self.status = self.Status.DUPLICATE
        self.save(update_fields=["status", "updated_at"])
    
    @classmethod
    def get_or_create_event(cls, idempotency_key, defaults):
        """
        Get existing event by idempotency key or create new one.
        Returns (event, created).
        """
        return cls.objects.get_or_create(
            idempotency_key=idempotency_key,
            defaults=defaults
        )
