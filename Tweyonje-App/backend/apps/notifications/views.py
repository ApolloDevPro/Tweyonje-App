from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Notification, NotificationDevice
from .serializers import NotificationSerializer


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    @action(detail=True, methods=["post"])
    def mark_as_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save(update_fields=["is_read", "updated_at"])
        return Response(NotificationSerializer(notif).data)

    @action(detail=False, methods=["post"])
    def mark_all_as_read(self, request):
        updated = Notification.objects.filter(recipient=request.user, is_read=False).update(
            is_read=True
        )
        return Response({"marked_read_count": updated})

    @action(detail=False, methods=["get"])
    def unread_count(self, request):
        count = Notification.objects.filter(recipient=request.user, is_read=False).count()
        return Response({"unread_count": count})

    @action(detail=False, methods=["post"])
    def register_device(self, request):
        """Register (or refresh) a push-notification token for the user."""
        token = (request.data.get("token") or "").strip()
        if not token:
            return Response({"error": "token is required."}, status=status.HTTP_400_BAD_REQUEST)

        device_type = str(request.data.get("device_type") or "mobile")[:32]
        device, created = NotificationDevice.objects.update_or_create(
            user=request.user,
            token=token,
            defaults={
                "device_type": device_type,
                "is_active": True,
                "last_seen_at": timezone.now(),
            },
        )
        return Response(
            {
                "token": device.token,
                "device_type": device.device_type,
                "is_active": device.is_active,
                "created": created,
            },
            status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=["post"])
    def unregister_device(self, request):
        """Deactivate a push-notification token for the user."""
        token = (request.data.get("token") or "").strip()
        if not token:
            return Response({"error": "token is required."}, status=status.HTTP_400_BAD_REQUEST)

        NotificationDevice.objects.filter(user=request.user, token=token).update(is_active=False)
        return Response({"success": True})
