from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.waste_requests.serializers import WasteRequestSerializer
from .models import ChatConversation, ChatMessage


class ChatMessageSerializer(serializers.ModelSerializer):
    sender_details = UserSerializer(source="sender", read_only=True)

    class Meta:
        model = ChatMessage
        fields = (
            "id",
            "conversation",
            "sender",
            "sender_details",
            "content",
            "is_read",
            "created_at",
        )
        read_only_fields = ("id", "conversation", "sender", "created_at")


class ChatConversationSerializer(serializers.ModelSerializer):
    waste_request_details = WasteRequestSerializer(source="waste_request", read_only=True)
    resident_details = UserSerializer(source="waste_request.user", read_only=True)
    collector_details = UserSerializer(source="collector", read_only=True)
    messages = ChatMessageSerializer(many=True, read_only=True)

    class Meta:
        model = ChatConversation
        fields = (
            "id",
            "waste_request",
            "waste_request_details",
            "resident_details",
            "collector_details",
            "messages",
            "is_active",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "waste_request",
            "collector",
            "created_at",
            "updated_at",
        )