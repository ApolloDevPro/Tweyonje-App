from django.contrib import admin

from .models import Invoice, Payment, Payout, Refund
from .models_webhook import WebhookEvent


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ("reference_id", "user", "amount", "currency", "method", "status", "created_at")
    list_filter = ("status", "method", "currency")
    search_fields = ("reference_id", "user__email", "phone_number", "transaction_id")


@admin.register(Payout)
class PayoutAdmin(admin.ModelAdmin):
    list_display = ("reference_id", "recipient", "amount", "currency", "status", "processed_at")
    list_filter = ("status", "currency")
    search_fields = ("reference_id", "recipient__email")


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ("invoice_number", "user", "amount", "currency", "is_paid", "issued_date")
    list_filter = ("is_paid",)
    search_fields = ("invoice_number", "user__email")


@admin.register(Refund)
class RefundAdmin(admin.ModelAdmin):
    list_display = ("payment", "amount", "status", "processed_by", "processed_at")
    list_filter = ("status",)


@admin.register(WebhookEvent)
class WebhookEventAdmin(admin.ModelAdmin):
    list_display = (
        "provider",
        "provider_reference",
        "status",
        "payment",
        "signature_verified",
        "retry_count",
        "created_at"
    )
    list_filter = ("provider", "status", "signature_verified", "created_at")
    search_fields = ("provider_reference", "idempotency_key", "payment__reference_id")
    readonly_fields = (
        "idempotency_key",
        "raw_body",
        "parsed_data",
        "raw_headers",
        "created_at",
        "updated_at"
    )
    fieldsets = (
        ("Identification", {
            "fields": ("provider", "provider_reference", "idempotency_key")
        }),
        ("Request Details", {
            "fields": ("http_method", "remote_ip", "user_agent", "raw_headers", "raw_body", "parsed_data")
        }),
        ("Processing", {
            "fields": ("status", "processed_at", "payment", "error_message", "retry_count", "last_retry_at")
        }),
        ("Security", {
            "fields": ("signature_verified", "signature_value")
        }),
        ("Timestamps", {
            "fields": ("created_at", "updated_at")
        }),
    )
    
    def has_add_permission(self, request):
        # Webhooks are created automatically, not manually
        return False
