from django.contrib import admin

from .models import IncidentReport, Rating, UserSuspension


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ("from_user", "to_user", "score", "waste_request", "created_at")
    list_filter = ("score", "is_public")
    search_fields = ("from_user__email", "to_user__email")


@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    list_display = ("category", "reported_by", "against_user", "status", "created_at")
    list_filter = ("status", "category")
    search_fields = ("reported_by__email", "against_user__email", "description")


@admin.register(UserSuspension)
class UserSuspensionAdmin(admin.ModelAdmin):
    list_display = ("user", "suspended_until", "is_active", "issued_by", "created_at")
    list_filter = ("is_active",)
    search_fields = ("user__email", "reason")
