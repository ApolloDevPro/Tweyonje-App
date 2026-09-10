from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from .models import IncidentReport, Rating, UserSuspension


class RatingSerializer(serializers.ModelSerializer):
    from_user_details = UserSerializer(source="from_user", read_only=True)
    to_user_details = UserSerializer(source="to_user", read_only=True)

    class Meta:
        model = Rating
        fields = (
            "id",
            "from_user",
            "from_user_details",
            "to_user",
            "to_user_details",
            "waste_request",
            "score",
            "review",
            "is_public",
            "created_at",
        )
        read_only_fields = ("id", "from_user", "created_at")


class IncidentReportSerializer(serializers.ModelSerializer):
    reported_by_details = UserSerializer(source="reported_by", read_only=True)
    against_user_details = UserSerializer(source="against_user", read_only=True)

    class Meta:
        model = IncidentReport
        fields = (
            "id",
            "reported_by",
            "reported_by_details",
            "against_user",
            "against_user_details",
            "waste_request",
            "category",
            "description",
            "evidence_photo",
            "status",
            "resolution_notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "reported_by", "created_at", "updated_at")


class UserSuspensionSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    issued_by_details = UserSerializer(source="issued_by", read_only=True)

    class Meta:
        model = UserSuspension
        fields = (
            "id",
            "user",
            "user_details",
            "reason",
            "suspended_until",
            "is_active",
            "issued_by",
            "issued_by_details",
            "created_at",
        )
        read_only_fields = ("id", "issued_by", "created_at")
