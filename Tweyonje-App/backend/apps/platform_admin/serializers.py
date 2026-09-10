from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from core.models import Role, SystemSetting, Zone
from .models import CollectorVerification, PolicyConsent, PrivacyPolicy


class ZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = Zone
        fields = ("id", "name", "code", "region", "description", "is_active")


class AdminUserSerializer(serializers.Serializer):
    """Admin-created account. Unlike self-service registration, any role is allowed."""

    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, write_only=True)
    full_name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=Role.choices, default=Role.RESIDENT)

    def validate_email(self, value):
        from django.contrib.auth import get_user_model

        User = get_user_model()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()

    def create(self, validated_data):
        from django.contrib.auth import get_user_model

        User = get_user_model()

        phone = validated_data.pop("phone", "")
        name_parts = validated_data.get("full_name", "").split(" ", 1)
        validated_data.setdefault("first_name", name_parts[0])
        validated_data.setdefault("last_name", name_parts[1] if len(name_parts) > 1 else "")
        user = User.objects.create_user(**validated_data)
        if phone:
            user.phone = phone
            user.save(update_fields=["phone"])

        from apps.profiles.models import Profile, NotificationPreference, Vehicle
        from apps.rewards.models import EcoWallet

        Profile.objects.get_or_create(user=user)
        NotificationPreference.objects.get_or_create(user=user)
        EcoWallet.objects.get_or_create(user=user)

        if user.role in (Role.COLLECTOR, Role.RECYCLER, Role.AUTHORITY):
            Vehicle.objects.get_or_create(
                user=user,
                defaults={"plate_number": f"UBA {user.id % 900 + 100}K"},
            )
        return user


class CollectorVerificationSerializer(serializers.ModelSerializer):
    collector_details = UserSerializer(source="collector", read_only=True)
    reviewer_details = UserSerializer(source="reviewer", read_only=True)

    class Meta:
        model = CollectorVerification
        fields = (
            "id",
            "collector",
            "collector_details",
            "national_id_number",
            "national_id_photo",
            "driving_license_number",
            "driving_license_photo",
            "vehicle_logbook_photo",
            "background_check_passed",
            "status",
            "reviewer",
            "reviewer_details",
            "reviewer_notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "status", "reviewer", "created_at", "updated_at")


class PrivacyPolicySerializer(serializers.ModelSerializer):
    published_by_details = UserSerializer(source="published_by", read_only=True)

    class Meta:
        model = PrivacyPolicy
        fields = (
            "id",
            "version",
            "title",
            "content",
            "is_active",
            "published_at",
            "published_by",
            "published_by_details",
            "created_at",
        )
        read_only_fields = ("id", "published_at", "published_by", "created_at")


class PolicyConsentSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    policy_details = PrivacyPolicySerializer(source="policy", read_only=True)

    class Meta:
        model = PolicyConsent
        fields = (
            "id",
            "user",
            "user_details",
            "policy",
            "policy_details",
            "consented_at",
            "ip_address",
        )
        read_only_fields = ("id", "user", "consented_at")


class SystemSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemSetting
        fields = ("id", "key", "value", "description")
