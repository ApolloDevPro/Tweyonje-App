from django.contrib import admin

from .models import LiveLocation, LocationHistory


@admin.register(LiveLocation)
class LiveLocationAdmin(admin.ModelAdmin):
    list_display = ("user", "vehicle", "latitude", "longitude", "speed_kmh", "last_updated")
    search_fields = ("user__email", "vehicle__plate_number")


@admin.register(LocationHistory)
class LocationHistoryAdmin(admin.ModelAdmin):
    list_display = ("user", "latitude", "longitude", "recorded_at")
    search_fields = ("user__email",)
