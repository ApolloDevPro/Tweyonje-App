from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.profiles.serializers import ZoneSerializer
from .models import (
    MarketplaceListing,
    RecyclableMaterial,
    RecyclingCenter,
    RecyclingTradeIn,
)


class RecyclableMaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecyclableMaterial
        fields = (
            "id",
            "name",
            "slug",
            "material_type",
            "price_per_kg",
            "point_multiplier",
            "description",
            "icon",
            "is_active",
        )


class RecyclingCenterSerializer(serializers.ModelSerializer):
    zone_details = ZoneSerializer(source="zone", read_only=True)
    accepted_materials_details = RecyclableMaterialSerializer(source="accepted_materials", many=True, read_only=True)

    class Meta:
        model = RecyclingCenter
        fields = (
            "id",
            "name",
            "address",
            "latitude",
            "longitude",
            "zone",
            "zone_details",
            "accepted_materials",
            "accepted_materials_details",
            "operating_hours",
            "phone",
            "email",
            "is_active",
        )


class MarketplaceListingSerializer(serializers.ModelSerializer):
    seller_details = UserSerializer(source="seller", read_only=True)
    material_details = RecyclableMaterialSerializer(source="material", read_only=True)

    class Meta:
        model = MarketplaceListing
        fields = (
            "id",
            "seller",
            "seller_details",
            "material",
            "material_details",
            "title",
            "description",
            "weight_kg",
            "price_ugx",
            "status",
            "location_address",
            "latitude",
            "longitude",
            "image",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "seller", "created_at", "updated_at")


class RecyclingTradeInSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    center_details = RecyclingCenterSerializer(source="center", read_only=True)
    material_details = RecyclableMaterialSerializer(source="material", read_only=True)

    class Meta:
        model = RecyclingTradeIn
        fields = (
            "id",
            "user",
            "user_details",
            "center",
            "center_details",
            "material",
            "material_details",
            "weight_kg",
            "amount_paid_ugx",
            "eco_points_earned",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "user", "amount_paid_ugx", "eco_points_earned", "created_at", "updated_at")
