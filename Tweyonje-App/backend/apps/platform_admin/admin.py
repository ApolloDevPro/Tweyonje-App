from django.contrib import admin

from core.models import SystemSetting, Zone
from .models import CollectorVerification, PolicyConsent, PrivacyPolicy


@admin.register(Zone)
class ZoneAdmin(admin.ModelAdmin):
    list_display = ("name", "code", "region", "is_active")
    search_fields = ("name", "code", "region")


@admin.register(SystemSetting)
class SystemSettingAdmin(admin.ModelAdmin):
    list_display = ("key", "value", "description")
    search_fields = ("key",)


@admin.register(CollectorVerification)
class CollectorVerificationAdmin(admin.ModelAdmin):
    list_display = ("collector", "national_id_number", "driving_license_number", "status", "reviewer", "created_at")
    list_filter = ("status", "background_check_passed")
    search_fields = ("collector__email", "national_id_number")


@admin.register(PrivacyPolicy)
class PrivacyPolicyAdmin(admin.ModelAdmin):
    list_display = ("version", "title", "is_active", "published_at", "published_by")
    list_filter = ("is_active",)


@admin.register(PolicyConsent)
class PolicyConsentAdmin(admin.ModelAdmin):
    list_display = ("user", "policy", "consented_at", "ip_address")
    search_fields = ("user__email", "policy__version")
