from django.contrib import admin

from .models import NotificationPreference, Profile, Site, Vehicle


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "zone", "address", "created_at")
    list_filter = ("role", "zone")
    search_fields = ("user__email", "user__full_name", "address")


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ("plate_number", "user", "vehicle_type", "capacity_kg", "is_default", "created_at")
    list_filter = ("vehicle_type", "is_default")
    search_fields = ("plate_number", "user__email")


@admin.register(Site)
class SiteAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "zone", "is_active", "created_at")
    list_filter = ("zone", "is_active")
    search_fields = ("name", "owner__email", "address")


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ("user", "push_enabled", "email_enabled", "sms_enabled")
    search_fields = ("user__email",)
