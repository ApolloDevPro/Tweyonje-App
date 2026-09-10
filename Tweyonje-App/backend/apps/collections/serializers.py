from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.profiles.serializers import VehicleSerializer, ZoneSerializer
from apps.waste_requests.serializers import WasteRequestSerializer
from .models import CollectionAssignment, CollectionSlot, CollectorShift


class CollectionSlotSerializer(serializers.ModelSerializer):
    zone_details = ZoneSerializer(source="zone", read_only=True)

    class Meta:
        model = CollectionSlot
        fields = (
            "id",
            "zone",
            "zone_details",
            "weekday",
            "start_time",
            "end_time",
            "max_capacity",
            "is_active",
            "created_at",
            "updated_at",
        )


class CollectionAssignmentSerializer(serializers.ModelSerializer):
    waste_request_details = WasteRequestSerializer(source="waste_request", read_only=True)
    collector_details = UserSerializer(source="collector", read_only=True)
    vehicle_details = VehicleSerializer(source="vehicle", read_only=True)

    class Meta:
        model = CollectionAssignment
        fields = (
            "id",
            "waste_request",
            "waste_request_details",
            "collector",
            "collector_details",
            "vehicle",
            "vehicle_details",
            "status",
            "assigned_at",
            "completed_at",
            "collected_weight_kg",
            "notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "status", "assigned_at", "created_at", "updated_at")


class CollectorShiftSerializer(serializers.ModelSerializer):
    collector_details = UserSerializer(source="collector", read_only=True)
    vehicle_details = VehicleSerializer(source="vehicle", read_only=True)

    class Meta:
        model = CollectorShift
        fields = (
            "id",
            "collector",
            "collector_details",
            "vehicle",
            "vehicle_details",
            "started_at",
            "ended_at",
            "is_active",
            "notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "collector", "started_at", "created_at", "updated_at")
