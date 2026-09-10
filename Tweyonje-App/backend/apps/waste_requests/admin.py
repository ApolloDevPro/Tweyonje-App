from django.contrib import admin

from .models import RecurringSchedule, WasteCategory, WasteRequest, WasteRequestPhoto


class WasteRequestPhotoInline(admin.TabularInline):
    model = WasteRequestPhoto
    extra = 0


@admin.register(WasteCategory)
class WasteCategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "is_hazardous", "default_price_per_kg", "base_eco_points", "is_active")
    list_filter = ("is_hazardous", "is_active")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(WasteRequest)
class WasteRequestAdmin(admin.ModelAdmin):
    list_display = (
        "reference_id",
        "user",
        "category",
        "zone",
        "status",
        "payment_status",
        "estimated_price",
        "is_emergency",
        "created_at",
    )
    list_filter = ("status", "payment_status", "is_emergency", "category", "zone")
    search_fields = ("reference_id", "user__email", "pickup_address")
    inlines = [WasteRequestPhotoInline]


@admin.register(RecurringSchedule)
class RecurringScheduleAdmin(admin.ModelAdmin):
    list_display = ("user", "category", "frequency", "preferred_weekday", "zone", "is_active")
    list_filter = ("frequency", "is_active", "zone")
    search_fields = ("user__email", "address")
