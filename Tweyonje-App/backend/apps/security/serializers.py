from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from .models import AuditLog, PasswordResetToken, SecurityEvent


class AuditLogSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = AuditLog
        fields = (
            "id",
            "user",
            "user_details",
            "action",
            "ip_address",
            "user_agent",
            "path",
            "method",
            "status_code",
            "metadata",
            "created_at",
        )


class SecurityEventSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = SecurityEvent
        fields = (
            "id",
            "event_type",
            "severity",
            "user",
            "user_details",
            "ip_address",
            "description",
            "metadata",
            "created_at",
        )
