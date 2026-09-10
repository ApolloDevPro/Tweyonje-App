from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from core.models import Zone
from .models import NotificationPreference, Profile, Site, Vehicle


class ZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = Zone
        fields = ("id", "name", "code", "region", "description", "is_active")


class ProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    zone_details = ZoneSerializer(source="zone", read_only=True)

    class Meta:
        model = Profile
        fields = (
            "id",
            "user",
            "role",
            "bio",
            "address",
            "latitude",
            "longitude",
            "avatar",
            "zone",
            "zone_details",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "role", "created_at", "updated_at")


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = (
            "id",
            "user",
            "plate_number",
            "vehicle_type",
            "capacity_kg",
            "is_default",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "user", "created_at", "updated_at")


class SiteSerializer(serializers.ModelSerializer):
    zone_details = ZoneSerializer(source="zone", read_only=True)

    class Meta:
        model = Site
        fields = (
            "id",
            "owner",
            "name",
            "address",
            "latitude",
            "longitude",
            "zone",
            "zone_details",
            "is_active",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "owner", "created_at", "updated_at")


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = (
            "id",
            "user",
            "push_enabled",
            "email_enabled",
            "sms_enabled",
            "quiet_hours_start",
            "quiet_hours_end",
            "categories",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "user", "created_at", "updated_at")
