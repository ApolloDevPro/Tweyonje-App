from django.contrib import admin

from .models import AuditLog, PasswordResetToken, SecurityEvent


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("action", "user", "method", "status_code", "ip_address", "created_at")
    list_filter = ("method", "status_code")
    search_fields = ("path", "action", "user__email", "ip_address")


@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "token", "is_used", "expires_at", "created_at")
    list_filter = ("is_used",)
    search_fields = ("user__email", "token")


@admin.register(SecurityEvent)
class SecurityEventAdmin(admin.ModelAdmin):
    list_display = ("event_type", "severity", "user", "ip_address", "created_at")
    list_filter = ("severity",)
    search_fields = ("event_type", "description", "user__email")
