from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.profiles.serializers import ZoneSerializer
from .models import RecurringSchedule, WasteCategory, WasteRequest, WasteRequestPhoto


class WasteCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = WasteCategory
        fields = (
            "id",
            "name",
            "slug",
            "description",
            "icon",
            "is_hazardous",
            "default_price_per_kg",
            "base_eco_points",
            "is_active",
        )


class WasteRequestPhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = WasteRequestPhoto
        fields = ("id", "waste_request", "photo", "caption", "photo_type", "created_at")
        read_only_fields = ("id", "created_at")


class WasteRequestSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    category_details = WasteCategorySerializer(source="category", read_only=True)
    zone_details = ZoneSerializer(source="zone", read_only=True)
    photos = WasteRequestPhotoSerializer(many=True, read_only=True)

    class Meta:
        model = WasteRequest
        fields = (
            "id",
            "reference_id",
            "user",
            "user_details",
            "category",
            "category_details",
            "schedule",
            "estimated_weight_kg",
            "actual_weight_kg",
            "pickup_address",
            "latitude",
            "longitude",
            "zone",
            "zone_details",
            "scheduled_date",
            "scheduled_time_slot",
            "special_instructions",
            "status",
            "is_emergency",
            "estimated_price",
            "paid_amount",
            "payment_status",
            "eco_points_awarded",
            "cancellation_reason",
            "photos",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "reference_id",
            "user",
            "status",
            "payment_status",
            "paid_amount",
            "eco_points_awarded",
            "created_at",
            "updated_at",
        )


class RecurringScheduleSerializer(serializers.ModelSerializer):
    category_details = WasteCategorySerializer(source="category", read_only=True)
    zone_details = ZoneSerializer(source="zone", read_only=True)

    class Meta:
        model = RecurringSchedule
        fields = (
            "id",
            "user",
            "category",
            "category_details",
            "frequency",
            "preferred_weekday",
            "preferred_time",
            "address",
            "latitude",
            "longitude",
            "zone",
            "zone_details",
            "is_active",
            "last_generated_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "user", "last_generated_at", "created_at", "updated_at")
