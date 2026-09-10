from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from apps.waste_requests.serializers import WasteRequestSerializer
from .models import Invoice, Payment, Payout, Refund


class PaymentSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    waste_request_details = WasteRequestSerializer(source="waste_request", read_only=True)

    class Meta:
        model = Payment
        fields = (
            "id",
            "reference_id",
            "user",
            "user_details",
            "waste_request",
            "waste_request_details",
            "amount",
            "currency",
            "method",
            "status",
            "phone_number",
            "transaction_id",
            "provider_reference",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "reference_id", "user", "status", "transaction_id", "provider_reference", "created_at", "updated_at")


class InitiatePaymentSerializer(serializers.Serializer):
    waste_request_id = serializers.UUIDField(required=False, allow_null=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)
    method = serializers.ChoiceField(choices=Payment.Method.choices, default=Payment.Method.MTN_MOMO)
    phone_number = serializers.CharField(max_length=32, required=False, allow_blank=True)


class PayoutSerializer(serializers.ModelSerializer):
    recipient_details = UserSerializer(source="recipient", read_only=True)

    class Meta:
        model = Payout
        fields = (
            "id",
            "reference_id",
            "recipient",
            "recipient_details",
            "amount",
            "currency",
            "phone_number",
            "status",
            "period_start",
            "period_end",
            "processed_at",
            "notes",
            "created_at",
        )
        read_only_fields = ("id", "reference_id", "recipient", "status", "processed_at", "created_at")


class InvoiceSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = Invoice
        fields = (
            "id",
            "invoice_number",
            "payment",
            "user",
            "user_details",
            "amount",
            "currency",
            "items_json",
            "issued_date",
            "is_paid",
        )


class RefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = (
            "id",
            "payment",
            "amount",
            "reason",
            "status",
            "processed_by",
            "processed_at",
            "created_at",
        )
