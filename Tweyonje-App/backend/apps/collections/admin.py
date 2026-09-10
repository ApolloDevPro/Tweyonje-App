from django.contrib import admin

from .models import CollectionAssignment, CollectionSlot, CollectorShift


@admin.register(CollectionSlot)
class CollectionSlotAdmin(admin.ModelAdmin):
    list_display = ("zone", "weekday", "start_time", "end_time", "max_capacity", "is_active")
    list_filter = ("zone", "weekday", "is_active")


@admin.register(CollectionAssignment)
class CollectionAssignmentAdmin(admin.ModelAdmin):
    list_display = ("waste_request", "collector", "vehicle", "status", "assigned_at", "completed_at")
    list_filter = ("status", "assigned_at")
    search_fields = ("waste_request__reference_id", "collector__email")


@admin.register(CollectorShift)
class CollectorShiftAdmin(admin.ModelAdmin):
    list_display = ("collector", "vehicle", "started_at", "ended_at", "is_active")
    list_filter = ("is_active", "started_at")
    search_fields = ("collector__email",)
