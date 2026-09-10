from django.contrib import admin

from .models import (
    MarketplaceListing,
    RecyclableMaterial,
    RecyclingCenter,
    RecyclingTradeIn,
)


@admin.register(RecyclableMaterial)
class RecyclableMaterialAdmin(admin.ModelAdmin):
    list_display = ("name", "material_type", "price_per_kg", "point_multiplier", "is_active")
    list_filter = ("material_type", "is_active")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(RecyclingCenter)
class RecyclingCenterAdmin(admin.ModelAdmin):
    list_display = ("name", "zone", "phone", "is_active")
    list_filter = ("zone", "is_active")
    search_fields = ("name", "address")


@admin.register(MarketplaceListing)
class MarketplaceListingAdmin(admin.ModelAdmin):
    list_display = ("title", "seller", "material", "weight_kg", "price_ugx", "status", "created_at")
    list_filter = ("status", "material")
    search_fields = ("title", "seller__email")


@admin.register(RecyclingTradeIn)
class RecyclingTradeInAdmin(admin.ModelAdmin):
    list_display = ("user", "center", "material", "weight_kg", "amount_paid_ugx", "eco_points_earned", "status")
    list_filter = ("status", "material")
