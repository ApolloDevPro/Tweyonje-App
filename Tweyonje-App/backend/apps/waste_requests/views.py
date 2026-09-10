from django.db import models
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from core.models import Role
from .models import RecurringSchedule, WasteCategory, WasteRequest, WasteRequestPhoto
from .serializers import (
    RecurringScheduleSerializer,
    WasteCategorySerializer,
    WasteRequestPhotoSerializer,
    WasteRequestSerializer,
)


class WasteCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = WasteCategory.objects.filter(is_active=True)
    serializer_class = WasteCategorySerializer


class WasteRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = WasteRequestSerializer
    filterset_fields = ["status", "category", "zone", "payment_status", "is_emergency"]
    search_fields = ["reference_id", "pickup_address", "user__email", "user__full_name"]
    ordering_fields = ["created_at", "scheduled_date", "estimated_price"]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return WasteRequest.objects.none()

        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            profile = getattr(user, "profile", None)
            if profile and profile.zone and user.role == Role.AUTHORITY:
                return WasteRequest.objects.filter(zone=profile.zone)
            return WasteRequest.objects.all()

        if user.role == Role.COLLECTOR:
            assigned_ids = user.collection_assignments.values_list("waste_request_id", flat=True)
            profile = getattr(user, "profile", None)
            if profile and profile.zone:
                return WasteRequest.objects.filter(
                    models.Q(id__in=assigned_ids) | models.Q(zone=profile.zone, status=WasteRequest.Status.PENDING)
                )
            return WasteRequest.objects.filter(id__in=assigned_ids)

        return WasteRequest.objects.filter(user=user)

    def perform_create(self, serializer):
        user = self.request.user
        zone = serializer.validated_data.get("zone")
        if not zone and hasattr(user, "profile") and user.profile.zone:
            zone = user.profile.zone
        serializer.save(user=user, zone=zone)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        from core.realtime import notify_request_update
        
        waste_req = self.get_object()
        if waste_req.status in (WasteRequest.Status.COLLECTED, WasteRequest.Status.CANCELLED):
            return Response(
                {"error": f"Cannot cancel request in {waste_req.status} status."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        waste_req.status = WasteRequest.Status.CANCELLED
        waste_req.cancellation_reason = request.data.get("reason", "Cancelled by user")
        waste_req.save(update_fields=["status", "cancellation_reason", "updated_at"])
        
        # Broadcast real-time update
        notify_request_update(waste_req)
        
        return Response(WasteRequestSerializer(waste_req).data)

    @action(detail=True, methods=["post"], parser_classes=[MultiPartParser, FormParser])
    def upload_photo(self, request, pk=None):
        from django.conf import settings
        from core.throttles import PhotoUploadThrottle
        
        # Apply throttling
        throttle = PhotoUploadThrottle()
        if not throttle.allow_request(request, self):
            return Response(
                {"error": "Too many photo uploads. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )
        
        waste_req = self.get_object()
        photo_file = request.FILES.get("photo")
        if not photo_file:
            return Response({"error": "No photo provided."}, status=status.HTTP_400_BAD_REQUEST)

        # Validate file size
        max_size = getattr(settings, 'MAX_PHOTO_SIZE_MB', 5) * 1024 * 1024
        if photo_file.size > max_size:
            return Response(
                {"error": f"Photo size exceeds {settings.MAX_PHOTO_SIZE_MB}MB limit."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
        if photo_file.content_type not in allowed_types:
            return Response(
                {"error": "Invalid file type. Only JPEG, PNG, and WebP images are allowed."},
                status=status.HTTP_400_BAD_REQUEST
            )

        caption = request.data.get("caption", "")
        photo_type = request.data.get("photo_type", WasteRequestPhoto.PhotoType.BEFORE_PICKUP)
        photo_obj = WasteRequestPhoto.objects.create(
            waste_request=waste_req,
            photo=photo_file,
            caption=caption,
            photo_type=photo_type,
        )
        return Response(WasteRequestPhotoSerializer(photo_obj).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def reschedule(self, request, pk=None):
        from core.realtime import notify_request_update
        
        waste_req = self.get_object()
        if waste_req.status in (WasteRequest.Status.COLLECTED, WasteRequest.Status.CANCELLED, WasteRequest.Status.REJECTED):
            return Response(
                {"error": f"Cannot reschedule request in {waste_req.status} status."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        scheduled_date = request.data.get("scheduled_date")
        scheduled_time_slot = request.data.get("scheduled_time_slot", "")

        if not scheduled_date:
            return Response(
                {"error": "scheduled_date is required (YYYY-MM-DD)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        waste_req.scheduled_date = scheduled_date
        waste_req.scheduled_time_slot = scheduled_time_slot
        if waste_req.status == WasteRequest.Status.PENDING:
            waste_req.status = WasteRequest.Status.SCHEDULED
        waste_req.save(update_fields=["scheduled_date", "scheduled_time_slot", "status", "updated_at"])
        
        # Broadcast real-time update
        notify_request_update(waste_req)
        
        return Response(WasteRequestSerializer(waste_req).data)

    @action(detail=True, methods=["get"])
    def payment_preview(self, request, pk=None):
        waste_req = self.get_object()
        return Response({
            "reference_id": waste_req.reference_id,
            "currency": "UGX",
            "amount": waste_req.estimated_price,
            "category": waste_req.category.name if waste_req.category else None,
            "quantity_kg": waste_req.estimated_weight_kg,
        })


class RecurringScheduleViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RecurringScheduleSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return RecurringSchedule.objects.all()
        return RecurringSchedule.objects.filter(user=user)

    def perform_create(self, serializer):
        user = self.request.user
        zone = serializer.validated_data.get("zone")
        if not zone and hasattr(user, "profile") and user.profile.zone:
            zone = user.profile.zone
        serializer.save(user=user, zone=zone)
