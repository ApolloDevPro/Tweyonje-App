import logging

from django.conf import settings
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role
from apps.waste_requests.models import WasteRequest
from .models import Invoice, Payment, Payout, Refund
from .serializers import (
    InitiatePaymentSerializer,
    InvoiceSerializer,
    PaymentSerializer,
    PayoutSerializer,
    RefundSerializer,
)
from .services import apply_provider_callback, initiate_momo_payment

logger = logging.getLogger(__name__)


class PaymentViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PaymentSerializer
    filterset_fields = ["status", "method", "currency"]
    search_fields = ["reference_id", "transaction_id", "user__email"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Payment.objects.all()
        return Payment.objects.filter(user=user)

    @action(detail=False, methods=["post"])
    def initiate(self, request):
        serializer = InitiatePaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        waste_req = None
        if data.get("waste_request_id"):
            waste_req = WasteRequest.objects.filter(id=data["waste_request_id"]).first()

        payment = initiate_momo_payment(
            user=request.user,
            waste_request=waste_req,
            phone=data.get("phone_number"),
            method=data.get("method", Payment.Method.MTN_MOMO),
            amount=data.get("amount"),
        )
        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)


class PayoutViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PayoutSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Payout.objects.all()
        return Payout.objects.filter(recipient=user)


class InvoiceViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = InvoiceSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Invoice.objects.all()
        return Invoice.objects.filter(user=user)


class PaymentSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from django.db.models import Sum

        user = request.user
        if user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        total_collected = Payment.objects.filter(status=Payment.Status.SUCCESSFUL).aggregate(
            total=Sum("amount")
        )["total"] or 0

        pending_amount = Payment.objects.filter(status=Payment.Status.PENDING).aggregate(
            total=Sum("amount")
        )["total"] or 0

        total_transactions = Payment.objects.count()
        successful_transactions = Payment.objects.filter(status=Payment.Status.SUCCESSFUL).count()
        success_rate = round((successful_transactions / total_transactions * 100), 2) if total_transactions > 0 else 100.0

        return Response({
            "total_collected_ugx": total_collected,
            "pending_amount_ugx": pending_amount,
            "total_transactions": total_transactions,
            "successful_transactions": successful_transactions,
            "success_rate_percent": success_rate,
            "currency": "UGX",
        })


class MoMoWebhookView(APIView):
    """Receives MTN MoMo requesttopay callbacks with idempotency support.

    MTN posts the final transaction object, e.g.
    ``{"referenceId": "...", "status": "SUCCESSFUL",
       "financialTransactionId": "...", "reason": null}``.

    Security: MTN MoMo callbacks do not sign their payloads, so we require a
    shared secret (``MTN_MOMO_CALLBACK_TOKEN``) supplied either via the
    ``Authorization: Bearer <token>`` header or a ``?token=`` query parameter.
    When the secret is not configured the webhook is disabled to prevent
    unauthenticated callers from marking payments as successful.
    
    Idempotency: Each webhook is logged with a unique key. Duplicate webhooks
    are detected and ignored.
    """

    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def _is_authorized(self, request) -> bool:
        callback_token = getattr(settings, "MTN_MOMO_CALLBACK_TOKEN", "")
        if not callback_token:
            # No secret configured -> never accept unsigned callbacks.
            return False
        header_token = request.META.get("HTTP_AUTHORIZATION", "")
        if header_token.startswith("Bearer "):
            header_token = header_token[len("Bearer "):]
        query_token = request.query_params.get("token", "")
        return header_token == callback_token or query_token == callback_token

    def post(self, request):
        from core.realtime import notify_payment_update
        from .models_webhook import WebhookEvent
        import hashlib
        
        if not self._is_authorized(request):
            return Response(
                {"received": False, "error": "Unauthorized."},
                status=status.HTTP_403_FORBIDDEN,
            )

        reference = (
            request.data.get("referenceId")
            or request.data.get("reference")
            or request.data.get("transaction_id")
        )
        status_value = str(request.data.get("status", "")).upper()
        transaction_id = request.data.get("financialTransactionId") or ""

        if not reference:
            return Response({"received": False, "error": "Missing reference."}, status=status.HTTP_400_BAD_REQUEST)

        # Generate idempotency key from reference + status
        idempotency_key = hashlib.sha256(
            f"mtn_momo:{reference}:{status_value}:{transaction_id}".encode()
        ).hexdigest()
        
        # Check if we've already processed this webhook
        event, created = WebhookEvent.get_or_create_event(
            idempotency_key=idempotency_key,
            defaults={
                "provider": WebhookEvent.Provider.MTN_MOMO,
                "provider_reference": str(reference),
                "http_method": request.method,
                "remote_ip": request.META.get("REMOTE_ADDR"),
                "user_agent": request.META.get("HTTP_USER_AGENT", ""),
                "raw_headers": dict(request.headers),
                "raw_body": str(request.body.decode("utf-8", errors="replace")),
                "parsed_data": dict(request.data),
                "signature_verified": True,  # Already verified by token check
            }
        )
        
        if not created:
            # Duplicate webhook - already processed
            event.mark_duplicate()
            logger.info(f"Duplicate MTN MoMo webhook ignored: {reference}")
            return Response({"received": True, "duplicate": True}, status=status.HTTP_200_OK)
        
        try:
            payment = apply_provider_callback(str(reference), status_value, str(transaction_id))
            
            if payment:
                event.mark_processed(payment)
                # Broadcast real-time update
                notify_payment_update(payment)
            else:
                event.mark_failed("Payment not found")
            
            return Response({"received": True, "matched": bool(payment)}, status=status.HTTP_200_OK)
            
        except Exception as exc:
            logger.exception(f"MTN MoMo webhook processing failed: {exc}")
            event.mark_failed(str(exc))
            return Response(
                {"received": True, "error": "Processing failed"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AirtelWebhookView(APIView):
    """Receives Airtel Money callbacks with HMAC-SHA256 signature verification."""

    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request):
        from core.realtime import notify_payment_update
        from .providers.airtel_money import AirtelMoneyClient
        from .models_webhook import WebhookEvent
        import hashlib

        # Fail closed: without a configured callback key no callback is trusted.
        if not settings.AIRTEL_CALLBACK_KEY:
            return Response(
                {"received": False, "error": "Unauthorized."},
                status=status.HTTP_403_FORBIDDEN,
            )

        signature = request.META.get("HTTP_X_SIGNATURE", "")
        raw_body = request.body
        if not AirtelMoneyClient.verify_webhook_signature(raw_body, signature):
            return Response({"received": False, "error": "Invalid signature."}, status=status.HTTP_403_FORBIDDEN)

        data = request.data
        txn = data.get("transaction") or {}
        if isinstance(txn, list):
            txn = txn[0] if txn else {}
        status_info = data.get("status") or {}
        reference = (
            txn.get("id")
            or txn.get("external_id")
            or (txn.get("reference") if isinstance(txn.get("reference"), str) else None)
        )
        status_code = txn.get("status_code") or status_info.get("code", "")
        message = status_info.get("message", "")

        # Map Airtel status codes to Tweyonje statuses.
        mapped = {"TS": "SUCCESSFUL", "TF": "FAILED"}.get(status_code, "")
        if not mapped:
            # Some payloads carry the final state in the message instead.
            upper_message = message.upper()
            if "SUCCESSFUL" in upper_message:
                mapped = "SUCCESSFUL"
            elif "FAILED" in upper_message:
                mapped = "FAILED"
        
        if not reference:
            # Signed but unmatchable payload - accept for idempotent logging only.
            logger.warning("Airtel callback without usable reference: %s", str(data)[:300])
            return Response({"received": True, "matched": False}, status=status.HTTP_200_OK)
        
        # Generate idempotency key
        idempotency_key = hashlib.sha256(
            f"airtel_money:{reference}:{mapped}:{status_code}".encode()
        ).hexdigest()
        
        # Check if already processed
        event, created = WebhookEvent.get_or_create_event(
            idempotency_key=idempotency_key,
            defaults={
                "provider": WebhookEvent.Provider.AIRTEL_MONEY,
                "provider_reference": str(reference),
                "http_method": request.method,
                "remote_ip": request.META.get("REMOTE_ADDR"),
                "user_agent": request.META.get("HTTP_USER_AGENT", ""),
                "raw_headers": dict(request.headers),
                "raw_body": raw_body.decode("utf-8", errors="replace"),
                "parsed_data": dict(data),
                "signature_verified": True,
                "signature_value": signature,
            }
        )
        
        if not created:
            event.mark_duplicate()
            logger.info(f"Duplicate Airtel Money webhook ignored: {reference}")
            return Response({"received": True, "duplicate": True}, status=status.HTTP_200_OK)
        
        try:
            payment = apply_provider_callback(str(reference), mapped or str(status_code), "")
            
            if payment:
                event.mark_processed(payment)
                # Broadcast real-time update
                notify_payment_update(payment)
            else:
                event.mark_failed("Payment not found")
            
            return Response({"received": True, "matched": bool(payment)}, status=status.HTTP_200_OK)
            
        except Exception as exc:
            logger.exception(f"Airtel Money webhook processing failed: {exc}")
            event.mark_failed(str(exc))
            return Response(
                {"received": True, "error": "Processing failed"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
