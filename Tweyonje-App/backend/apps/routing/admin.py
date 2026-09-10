from django.contrib import admin

from .models import RoutePlan


@admin.register(RoutePlan)
class RoutePlanAdmin(admin.ModelAdmin):
    list_display = ("collector", "date", "status", "total_distance_km", "estimated_duration_minutes", "created_at")
    list_filter = ("status", "date")
    search_fields = ("collector__email",)
