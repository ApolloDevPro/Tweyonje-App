from rest_framework import serializers

from core.models import Role
from apps.accounts.serializers import UserSerializer
from apps.profiles.serializers import ZoneSerializer
from .models import IllegalDumpingReport, ReportPhoto


class ReportPhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReportPhoto
        fields = ("id", "report", "photo", "caption", "created_at")
        read_only_fields = ("id", "created_at")


class IllegalDumpingReportSerializer(serializers.ModelSerializer):
    reported_by_details = UserSerializer(source="reported_by", read_only=True)
    zone_details = ZoneSerializer(source="zone", read_only=True)
    photos = ReportPhotoSerializer(many=True, read_only=True)

    class Meta:
        model = IllegalDumpingReport
        fields = (
            "id",
            "reference_id",
            "reported_by",
            "reported_by_details",
            "is_anonymous",
            "address",
            "latitude",
            "longitude",
            "zone",
            "zone_details",
            "description",
            "severity",
            "status",
            "resolution_notes",
            "eco_points_awarded",
            "photos",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "reference_id",
            "reported_by",
            "eco_points_awarded",
            "created_at",
            "updated_at",
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get("request")
        user = getattr(request, "user", None)
        is_privileged = bool(
            user
            and user.is_authenticated
            and user.role in (Role.ADMINISTRATOR, Role.AUTHORITY)
        )
        # Reporter identity is only revealed to authorities/admins and only for
        # non-anonymous reports.
        if instance.is_anonymous or not is_privileged:
            data["reported_by"] = None
            data["reported_by_details"] = None
        return data
