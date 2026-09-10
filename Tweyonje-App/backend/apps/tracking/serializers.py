import math
from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.profiles.serializers import VehicleSerializer
from .models import LiveLocation, LocationHistory


def calculate_haversine_distance_km(lat1, lon1, lat2, lon2):
    R = 6371.0  # Earth's radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)


class LiveLocationSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    vehicle_details = VehicleSerializer(source="vehicle", read_only=True)

    class Meta:
        model = LiveLocation
        fields = (
            "id",
            "user",
            "user_details",
            "vehicle",
            "vehicle_details",
            "latitude",
            "longitude",
            "heading",
            "speed_kmh",
            "last_updated",
        )
        read_only_fields = ("id", "user", "last_updated")


class UpdateLocationSerializer(serializers.Serializer):
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    heading = serializers.DecimalField(max_digits=5, decimal_places=2, required=False, allow_null=True)
    speed_kmh = serializers.DecimalField(max_digits=5, decimal_places=2, required=False, allow_null=True)
    vehicle_id = serializers.UUIDField(required=False, allow_null=True)


class LocationHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LocationHistory
        fields = ("id", "user", "latitude", "longitude", "recorded_at")
