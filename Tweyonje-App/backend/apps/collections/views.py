from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role
from apps.waste_requests.models import WasteRequest
from .models import CollectionAssignment, CollectionSlot, CollectorShift
from .serializers import (
    CollectionAssignmentSerializer,
    CollectionSlotSerializer,
    CollectorShiftSerializer,
)
from .services import complete_collection


class CollectionSlotViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CollectionSlotSerializer
    queryset = CollectionSlot.objects.filter(is_active=True)
    filterset_fields = ["zone", "weekday", "is_active"]


class CollectionAssignmentViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CollectionAssignmentSerializer
    filterset_fields = ["status", "collector", "vehicle"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return CollectionAssignment.objects.all()
        if user.role == Role.COLLECTOR:
            return CollectionAssignment.objects.filter(collector=user)
        # Residents see assignments for their own waste requests
        return CollectionAssignment.objects.filter(waste_request__user=user)

    def _is_admin(self, user) -> bool:
        return user.role in (Role.ADMINISTRATOR, Role.AUTHORITY)

    def _is_assigned_collector(self, user, assignment) -> bool:
        return user.role == Role.COLLECTOR and assignment.collector_id == user.id

    def perform_create(self, serializer):
        from core.realtime import notify_request_update
        
        user = self.request.user
        if not self._is_admin(user):
            raise PermissionDenied("Only authorities/administrators can create collection assignments.")
        assignment = serializer.save()
        # Update request status to ASSIGNED
        req = assignment.waste_request
        req.status = WasteRequest.Status.ASSIGNED
        req.save(update_fields=["status", "updated_at"])
        
        # Broadcast real-time update
        notify_request_update(req)

    def _ensure_can_manage(self, assignment):
        """Raise PermissionDenied unless the user may act on this assignment."""
        user = self.request.user
        if self._is_admin(user) or self._is_assigned_collector(user, assignment):
            return
        raise PermissionDenied("You do not have permission to perform this action.")

    @action(detail=True, methods=["post"])
    def start_trip(self, request, pk=None):
        from core.realtime import notify_request_update
        
        assignment = self.get_object()
        self._ensure_can_manage(assignment)
        assignment.status = CollectionAssignment.Status.EN_ROUTE
        assignment.save(update_fields=["status", "updated_at"])
        
        req = assignment.waste_request
        req.status = WasteRequest.Status.IN_PROGRESS
        req.save(update_fields=["status", "updated_at"])
        
        # Broadcast real-time update
        notify_request_update(req)
        
        return Response(CollectionAssignmentSerializer(assignment).data)

    @action(detail=True, methods=["post"])
    def arrive(self, request, pk=None):
        from core.realtime import notify_request_update
        
        assignment = self.get_object()
        self._ensure_can_manage(assignment)
        assignment.status = CollectionAssignment.Status.ARRIVED
        assignment.save(update_fields=["status", "updated_at"])
        
        # Broadcast real-time update
        notify_request_update(assignment.waste_request)
        
        return Response(CollectionAssignmentSerializer(assignment).data)

    @action(detail=True, methods=["post"])
    def complete(self, request, pk=None):
        from core.realtime import notify_request_update
        
        assignment = self.get_object()
        self._ensure_can_manage(assignment)
        weight = request.data.get("collected_weight_kg")
        notes = request.data.get("notes", "")
        updated_assignment = complete_collection(assignment, collected_weight_kg=weight, notes=notes)
        
        # Broadcast real-time update
        notify_request_update(updated_assignment.waste_request)
        
        return Response(CollectionAssignmentSerializer(updated_assignment).data)

    @action(detail=True, methods=["post"])
    def verify(self, request, pk=None):
        assignment = self.get_object()
        if not self._is_admin(request.user):
            raise PermissionDenied("Only authorities/administrators can verify collections.")
        assignment.status = CollectionAssignment.Status.VERIFIED
        assignment.save(update_fields=["status", "updated_at"])
        return Response(CollectionAssignmentSerializer(assignment).data)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        assignment = self.get_object()
        self._ensure_can_manage(assignment)
        if assignment.status != CollectionAssignment.Status.ASSIGNED:
            return Response(
                {"error": f"Cannot reject assignment in {assignment.status} status."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        assignment.status = CollectionAssignment.Status.CANCELLED
        assignment.notes = request.data.get("reason", "Rejected by collector")
        assignment.save(update_fields=["status", "notes", "updated_at"])

        req = assignment.waste_request
        req.status = WasteRequest.Status.PENDING
        req.cancellation_reason = assignment.notes
        req.save(update_fields=["status", "cancellation_reason", "updated_at"])
        return Response(CollectionAssignmentSerializer(assignment).data)


class CollectorShiftViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CollectorShiftSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return CollectorShift.objects.all()
        return CollectorShift.objects.filter(collector=user)

    def perform_create(self, serializer):
        serializer.save(collector=self.request.user)

    @action(detail=True, methods=["post"])
    def end_shift(self, request, pk=None):
        shift = self.get_object()
        shift.is_active = False
        shift.ended_at = timezone.now()
        shift.save(update_fields=["is_active", "ended_at", "updated_at"])
        return Response(CollectorShiftSerializer(shift).data)


class CollectorDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        today = timezone.now().date()
        assignments = CollectionAssignment.objects.filter(collector=user)
        
        today_assignments = assignments.filter(assigned_at__date=today)
        pending_jobs = assignments.filter(status__in=[
            CollectionAssignment.Status.ASSIGNED,
            CollectionAssignment.Status.EN_ROUTE,
            CollectionAssignment.Status.ARRIVED,
        ])
        completed_today = today_assignments.filter(status=CollectionAssignment.Status.COLLECTED)

        total_weight_collected_today = sum(
            float(a.collected_weight_kg or 0) for a in completed_today
        )

        active_shift = CollectorShift.objects.filter(collector=user, is_active=True).first()

        return Response({
            "collector": user.email,
            "active_shift": CollectorShiftSerializer(active_shift).data if active_shift else None,
            "today_total_jobs": today_assignments.count(),
            "completed_today": completed_today.count(),
            "pending_jobs_count": pending_jobs.count(),
            "total_weight_collected_kg": total_weight_collected_today,
            "active_assignments": CollectionAssignmentSerializer(pending_jobs, many=True).data,
        })
