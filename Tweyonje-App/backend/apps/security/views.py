from rest_framework import permissions, viewsets

from core.models import Role
from .models import AuditLog, SecurityEvent
from .serializers import AuditLogSerializer, SecurityEventSerializer


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AuditLogSerializer
    filterset_fields = ["method", "status_code"]
    search_fields = ["path", "action", "user__email", "ip_address"]

    def get_queryset(self):
        user = self.request.user
        if user.role != Role.ADMINISTRATOR:
            return AuditLog.objects.none()
        return AuditLog.objects.all()


class SecurityEventViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SecurityEventSerializer
    filterset_fields = ["severity", "event_type"]
    search_fields = ["description", "user__email", "ip_address"]

    def get_queryset(self):
        user = self.request.user
        if user.role != Role.ADMINISTRATOR:
            return SecurityEvent.objects.none()
        return SecurityEvent.objects.all()
