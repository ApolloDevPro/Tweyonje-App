from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.waste_requests.serializers import WasteRequestSerializer
from .models import Dispute, SupportTicket, TicketMessage


class TicketMessageSerializer(serializers.ModelSerializer):
    sender_details = UserSerializer(source="sender", read_only=True)

    class Meta:
        model = TicketMessage
        fields = (
            "id",
            "ticket",
            "sender",
            "sender_details",
            "message",
            "attachment",
            "is_internal",
            "created_at",
        )
        read_only_fields = ("id", "sender", "created_at")


class SupportTicketSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    assigned_to_details = UserSerializer(source="assigned_to", read_only=True)
    messages = TicketMessageSerializer(many=True, read_only=True)

    class Meta:
        model = SupportTicket
        fields = (
            "id",
            "ticket_number",
            "user",
            "user_details",
            "subject",
            "category",
            "priority",
            "status",
            "assigned_to",
            "assigned_to_details",
            "sla_deadline",
            "is_escalated",
            "messages",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "ticket_number", "user", "sla_deadline", "is_escalated", "created_at", "updated_at")


class DisputeSerializer(serializers.ModelSerializer):
    waste_request_details = WasteRequestSerializer(source="waste_request", read_only=True)
    raised_by_details = UserSerializer(source="raised_by", read_only=True)
    resolved_by_details = UserSerializer(source="resolved_by", read_only=True)

    class Meta:
        model = Dispute
        fields = (
            "id",
            "reference_id",
            "waste_request",
            "waste_request_details",
            "raised_by",
            "raised_by_details",
            "reason",
            "evidence_photo",
            "resolution",
            "resolution_notes",
            "resolved_by",
            "resolved_by_details",
            "resolved_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "reference_id", "raised_by", "resolved_by", "resolved_at", "created_at", "updated_at")
