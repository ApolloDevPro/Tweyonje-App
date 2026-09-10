from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from .models import RoutePlan


class RoutePlanSerializer(serializers.ModelSerializer):
    collector_details = UserSerializer(source="collector", read_only=True)

    class Meta:
        model = RoutePlan
        fields = (
            "id",
            "collector",
            "collector_details",
            "date",
            "status",
            "total_distance_km",
            "estimated_duration_minutes",
            "waypoints_order_json",
            "created_at",
            "updated_at",
        )
