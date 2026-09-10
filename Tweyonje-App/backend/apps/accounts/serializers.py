import random
import secrets
import string

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from core.models import Role
from .models import OTPVerification

User = get_user_model()

# Roles that self-service registration is allowed to use.
# COLLECTOR, RECYCLER, AUTHORITY, and ADMINISTRATOR require admin approval.
ALLOWED_REGISTRATION_ROLES = {Role.RESIDENT, Role.BUSINESS}


def _generate_ref():
    return secrets.token_urlsafe(8).upper()[:10]


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "phone",
            "full_name",
            "first_name",
            "last_name",
            "role",
            "preferred_language",
            "phone_verified",
            "email_verified",
            "consent_policy_version",
            "date_joined",
        )
        read_only_fields = ("id", "date_joined", "phone_verified", "email_verified")


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, write_only=True)
    full_name = serializers.CharField(max_length=255)
    role = serializers.ChoiceField(choices=Role.choices, default=Role.RESIDENT)

    def validate_role(self, value):
        if value not in ALLOWED_REGISTRATION_ROLES:
            raise serializers.ValidationError(
                "Self-service registration is only allowed for Resident and Business roles."
            )
        return value
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    consent_policy_version = serializers.CharField(max_length=64, required=False, allow_blank=True)
    preferred_language = serializers.CharField(max_length=8, required=False, default="en")
    company_name = serializers.CharField(max_length=255, required=False, allow_blank=True)
    tin = serializers.CharField(max_length=64, required=False, allow_blank=True)
    id_number = serializers.CharField(max_length=64, required=False, allow_blank=True)
    vehicle_plate = serializers.CharField(max_length=32, required=False, allow_blank=True)

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()

    def create(self, validated_data):
        company_name = validated_data.pop("company_name", "")
        tin = validated_data.pop("tin", "")
        id_number = validated_data.pop("id_number", "")
        vehicle_plate = validated_data.pop("vehicle_plate", "")
        name_parts = validated_data.get("full_name", "").split(" ", 1)
        validated_data.setdefault("first_name", name_parts[0])
        validated_data.setdefault("last_name", name_parts[1] if len(name_parts) > 1 else "")
        user = User.objects.create_user(**validated_data)

        from apps.profiles.models import Profile, Vehicle, NotificationPreference
        from apps.rewards.models import EcoWallet

        Profile.objects.get_or_create(user=user)
        NotificationPreference.objects.get_or_create(user=user)
        EcoWallet.objects.get_or_create(user=user)

        if vehicle_plate or user.role == Role.COLLECTOR:
            Vehicle.objects.get_or_create(
                user=user,
                defaults={"plate_number": vehicle_plate or f"UBA {random.randint(100, 999)}K"},
            )
        return user


class LoginSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        email_or_phone = (attrs.get("email") or attrs.get("username") or "").strip()
        if email_or_phone and "@" not in email_or_phone:
            from core.models import User
            user_by_phone = User.objects.filter(phone=email_or_phone).first()
            if user_by_phone:
                attrs["email"] = user_by_phone.email
        data = super().validate(attrs)
        data["user"] = UserSerializer(self.user).data
        return data


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate_refresh(self, value):
        from rest_framework_simplejwt.exceptions import TokenError

        try:
            token = RefreshToken(value)
        except TokenError as exc:
            raise serializers.ValidationError("Invalid refresh token.") from exc
        token.blacklist()
        return value


class SendOTPSerializer(serializers.Serializer):
    identifier = serializers.CharField(max_length=255)
    purpose = serializers.ChoiceField(
        choices=OTPVerification.Purpose.choices,
        default=OTPVerification.Purpose.PHONE_VERIFY,
    )


class VerifyOTPSerializer(serializers.Serializer):
    identifier = serializers.CharField(max_length=255)
    otp_code = serializers.CharField(max_length=8)
    purpose = serializers.ChoiceField(
        choices=OTPVerification.Purpose.choices,
        required=False,
    )


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def save(self):
        email = self.validated_data["email"].lower()
        user = User.objects.filter(email__iexact=email).first()
        dev_token = None
        if user:
            dev_token = _generate_ref()
            from apps.security.models import PasswordResetToken

            PasswordResetToken.objects.create(user=user, token=dev_token)

            if settings.EMAIL_HOST:
                send_mail(
                    "Tweyonje password reset",
                    f"Use this token to reset your password: {dev_token}",
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=True,
                )
        result = {"sent": True}
        # Only expose the reset token in development for testing convenience
        if dev_token and settings.DEBUG:
            result["dev_token"] = dev_token
        return result


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(min_length=8, write_only=True)

    def save(self):
        from apps.security.models import PasswordResetToken

        token = PasswordResetToken.objects.filter(
            token=self.validated_data["token"],
            is_used=False,
            expires_at__gt=timezone.now(),
        ).select_related("user").first()
        if not token:
            raise serializers.ValidationError("Invalid or expired token.")
        user = token.user
        user.set_password(self.validated_data["new_password"])
        user.save(update_fields=["password"])
        token.is_used = True
        token.save(update_fields=["is_used"])
        return user
