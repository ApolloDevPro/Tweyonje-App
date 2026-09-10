from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from core.models import Role
from .models import IllegalDumpingReport, ReportPhoto
from .serializers import (
    IllegalDumpingReportSerializer,
    ReportPhotoSerializer,
)


class IllegalDumpingReportViewSet(viewsets.ModelViewSet):
    serializer_class = IllegalDumpingReportSerializer
    filterset_fields = ["status", "severity", "zone", "is_anonymous"]
    search_fields = ["reference_id", "address", "description"]
    ordering_fields = ["created_at", "severity"]

    def get_permissions(self):
        # Anyone may submit a report (anonymous dumping reports), but reading
        # report data - which may include the reporter's identity - requires
        # an account.
        if self.action == "create":
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            # Public/unauthenticated can see non-dismissed reports on map
            return IllegalDumpingReport.objects.exclude(status=IllegalDumpingReport.Status.DISMISSED)

        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            profile = getattr(user, "profile", None)
            if profile and profile.zone and user.role == Role.AUTHORITY:
                return IllegalDumpingReport.objects.filter(zone=profile.zone)
            return IllegalDumpingReport.objects.all()

        return IllegalDumpingReport.objects.all()

    def perform_create(self, serializer):
        user = self.request.user if self.request.user.is_authenticated else None
        zone = serializer.validated_data.get("zone")
        if not zone and user and hasattr(user, "profile") and user.profile.zone:
            zone = user.profile.zone
        serializer.save(reported_by=user, zone=zone)

    @action(detail=True, methods=["post"], parser_classes=[MultiPartParser, FormParser])
    def upload_photo(self, request, pk=None):
        report = self.get_object()
        photo_file = request.FILES.get("photo")
        if not photo_file:
            return Response({"error": "No photo provided."}, status=status.HTTP_400_BAD_REQUEST)
        
        caption = request.data.get("caption", "")
        photo_obj = ReportPhoto.objects.create(
            report=report,
            photo=photo_file,
            caption=caption,
        )
        return Response(ReportPhotoSerializer(photo_obj).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def resolve(self, request, pk=None):
        report = self.get_object()
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Only authorities/administrators can resolve reports."}, status=status.HTTP_403_FORBIDDEN)

        report.status = IllegalDumpingReport.Status.RESOLVED
        report.resolution_notes = request.data.get("resolution_notes", "Resolved by authority")
        
        # Award eco-points to reporter if not anonymous
        if report.reported_by and not report.eco_points_awarded:
            from apps.rewards.services import award_eco_points
            points = 25  # standard award for verified environmental report
            award_eco_points(
                user=report.reported_by,
                points=points,
                transaction_type="EARNED_REPORT",
                source_id=str(report.id),
                description=f"Eco-points for verified illegal dumping report ({report.reference_id})",
            )
            report.eco_points_awarded = points

        report.save(update_fields=["status", "resolution_notes", "eco_points_awarded", "updated_at"])
        return Response(IllegalDumpingReportSerializer(report).data)
