from django.contrib import admin
from django.contrib.auth import get_user_model
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import OTPVerification

User = get_user_model()


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ("email", "full_name", "role", "phone", "phone_verified", "email_verified", "is_active", "date_joined")
    list_filter = ("role", "phone_verified", "email_verified", "is_active", "is_staff")
    search_fields = ("email", "full_name", "first_name", "last_name", "phone")
    ordering = ("-date_joined",)
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal info", {"fields": ("full_name", "first_name", "last_name", "phone", "role", "preferred_language")}),
        ("Verifications", {"fields": ("phone_verified", "email_verified", "consent_policy_version")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "full_name", "role", "password1", "password2"),
            },
        ),
    )


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display = ("identifier", "purpose", "is_verified", "attempts", "expires_at", "created_at")
    list_filter = ("purpose", "is_verified")
    search_fields = ("identifier",)
    ordering = ("-created_at",)
