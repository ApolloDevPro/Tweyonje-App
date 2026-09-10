from django.db.models import Count
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role
from .models import Dispute, SupportTicket, TicketMessage
from .serializers import (
    DisputeSerializer,
    SupportTicketSerializer,
    TicketMessageSerializer,
)


class SupportTicketViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SupportTicketSerializer
    filterset_fields = ["status", "category", "priority", "is_escalated"]
    search_fields = ["ticket_number", "subject", "user__email"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return SupportTicket.objects.all()
        return SupportTicket.objects.filter(user=user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"], parser_classes=[MultiPartParser, FormParser])
    def add_message(self, request, pk=None):
        from core.realtime import notify_support_update
        
        ticket = self.get_object()
        message_text = request.data.get("message")
        if not message_text:
            return Response({"error": "Message is required."}, status=status.HTTP_400_BAD_REQUEST)

        attachment = request.FILES.get("attachment")
        is_internal = request.data.get("is_internal", False)
        if is_internal and request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            is_internal = False

        msg = TicketMessage.objects.create(
            ticket=ticket,
            sender=request.user,
            message=message_text,
            attachment=attachment,
            is_internal=is_internal,
        )

        if ticket.status == SupportTicket.Status.RESOLVED and request.user == ticket.user:
            ticket.status = SupportTicket.Status.IN_PROGRESS
            ticket.save(update_fields=["status", "updated_at"])

        # Broadcast real-time update
        notify_support_update(ticket)

        return Response(TicketMessageSerializer(msg).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def close_ticket(self, request, pk=None):
        from core.realtime import notify_support_update
        
        ticket = self.get_object()
        ticket.status = SupportTicket.Status.CLOSED
        ticket.save(update_fields=["status", "updated_at"])
        
        # Broadcast real-time update
        notify_support_update(ticket)
        
        return Response(SupportTicketSerializer(ticket).data)


class DisputeViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = DisputeSerializer
    filterset_fields = ["resolution"]
    search_fields = ["reference_id", "reason", "waste_request__reference_id"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Dispute.objects.all()
        return Dispute.objects.filter(raised_by=user)

    def perform_create(self, serializer):
        serializer.save(raised_by=self.request.user)

    @action(detail=True, methods=["post"])
    def resolve(self, request, pk=None):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        dispute = self.get_object()
        resolution = request.data.get("resolution")
        notes = request.data.get("resolution_notes", "")

        if resolution not in Dispute.Resolution.values:
            return Response({"error": "Invalid resolution value."}, status=status.HTTP_400_BAD_REQUEST)

        dispute.resolution = resolution
        dispute.resolution_notes = notes
        dispute.resolved_by = request.user
        dispute.resolved_at = timezone.now()
        dispute.save()

        # If REFUND_RESIDENT, auto-trigger refund creation
        if resolution == Dispute.Resolution.REFUND_RESIDENT:
            from apps.payments.services import create_refund_for_request
            create_refund_for_request(
                waste_request=dispute.waste_request,
                reason=f"Dispute resolved: {notes}",
                admin_user=request.user,
            )

        return Response(DisputeSerializer(dispute).data)


class DisputeMetricsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        total = Dispute.objects.count()
        by_resolution = Dispute.objects.values("resolution").annotate(count=Count("id"))
        pending_count = Dispute.objects.filter(resolution=Dispute.Resolution.PENDING).count()

        return Response({
            "total_disputes": total,
            "pending_count": pending_count,
            "resolution_breakdown": list(by_resolution),
        })


class DisputeExportView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        disputes = Dispute.objects.all().select_related("waste_request", "raised_by")
        data = []
        for d in disputes:
            data.append({
                "reference_id": d.reference_id,
                "request_ref": d.waste_request.reference_id,
                "raised_by": d.raised_by.email,
                "reason": d.reason,
                "resolution": d.resolution,
                "created_at": d.created_at.isoformat(),
                "resolved_at": d.resolved_at.isoformat() if d.resolved_at else None,
            })
        return Response({"disputes": data})
