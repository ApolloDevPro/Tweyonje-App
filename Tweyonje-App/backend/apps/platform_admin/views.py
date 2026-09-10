from django.contrib.auth import get_user_model
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role, SystemSetting, Zone
from apps.accounts.serializers import UserSerializer
from apps.collections.models import CollectionAssignment
from apps.payments.models import Payment, Payout
from apps.reports.models import IllegalDumpingReport
from apps.rewards.models import PointTransaction
from apps.waste_requests.models import WasteRequest
from .models import CollectorVerification, PolicyConsent, PrivacyPolicy
from .serializers import (
    AdminUserSerializer,
    CollectorVerificationSerializer,
    PolicyConsentSerializer,
    PrivacyPolicySerializer,
    SystemSettingSerializer,
    ZoneSerializer,
)

User = get_user_model()


class AdminUsersApi(APIView):
    """Platform admin only: list all accounts and create accounts for any role."""

    permission_classes = [permissions.IsAuthenticated]

    def _require_admin(self, request):
        if request.user.role != Role.ADMINISTRATOR:
            return Response(
                {"detail": "Administrator permission required."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return None

    def get(self, request):
        denied = self._require_admin(request)
        if denied:
            return denied
        users = User.objects.all().order_by("-date_joined")
        return Response([UserSerializer(u).data for u in users])

    def post(self, request):
        denied = self._require_admin(request)
        if denied:
            return denied

        serializer = AdminUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        return Response(
            {
                "detail": "Account created successfully.",
                "user": UserSerializer(user).data,
            },
            status=status.HTTP_201_CREATED,
        )


class ZoneViewSet(viewsets.ModelViewSet):
    serializer_class = ZoneSerializer
    queryset = Zone.objects.all()

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    @action(detail=True, methods=["post"])
    def assign_collector(self, request, pk=None):
        """Assign a collector profile to this zone.

        Body: {"user_id": <int>}
        """
        if request.user.role != Role.ADMINISTRATOR:
            return Response(
                {"detail": "Administrator permission required."},
                status=status.HTTP_403_FORBIDDEN,
            )
        user_id = request.data.get("user_id")
        if not user_id:
            return Response(
                {"error": "user_id is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        if user.role != Role.COLLECTOR:
            return Response(
                {"error": "Only collectors can be assigned to zones."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        zone = self.get_object()
        profile = user.profile
        profile.zone = zone
        profile.save(update_fields=["zone", "updated_at"])
        return Response(
            {"detail": f"Collector assigned to {zone.name}.", "zone_id": str(zone.id)},
            status=status.HTTP_200_OK,
        )


class SystemSettingViewSet(viewsets.ModelViewSet):
    serializer_class = SystemSettingSerializer
    queryset = SystemSetting.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role != Role.ADMINISTRATOR:
            return SystemSetting.objects.none()
        return SystemSetting.objects.all()


class CollectorVerificationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CollectorVerificationSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return CollectorVerification.objects.all()
        return CollectorVerification.objects.filter(collector=user)

    def perform_create(self, serializer):
        serializer.save(collector=self.request.user)

    @action(detail=True, methods=["post"])
    def approve(self, request, pk=None):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin permission required."}, status=status.HTTP_403_FORBIDDEN)

        verification = self.get_object()
        verification.status = CollectorVerification.Status.APPROVED
        verification.reviewer = request.user
        verification.reviewer_notes = request.data.get("notes", "Approved by admin")
        verification.save()

        verification.collector.role = Role.COLLECTOR
        verification.collector.save(update_fields=["role"])

        return Response(CollectorVerificationSerializer(verification).data)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin permission required."}, status=status.HTTP_403_FORBIDDEN)

        verification = self.get_object()
        verification.status = CollectorVerification.Status.REJECTED
        verification.reviewer = request.user
        verification.reviewer_notes = request.data.get("notes", "Rejected")
        verification.save()

        return Response(CollectorVerificationSerializer(verification).data)


class PrivacyPolicyViewSet(viewsets.ModelViewSet):
    serializer_class = PrivacyPolicySerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve", "current"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        if self.action in ("list", "retrieve", "current"):
            return PrivacyPolicy.objects.filter(is_active=True)
        return PrivacyPolicy.objects.all()

    @action(detail=False, methods=["get"])
    def current(self, request):
        policy = PrivacyPolicy.objects.filter(is_active=True).first()
        if not policy:
            return Response({"detail": "No active privacy policy found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(PrivacyPolicySerializer(policy).data)


class PublishPrivacyPolicyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if request.user.role != Role.ADMINISTRATOR:
            return Response({"error": "Admin permission required."}, status=status.HTTP_403_FORBIDDEN)

        version = request.data.get("version")
        content = request.data.get("content")
        title = request.data.get("title", "Tweyonje Privacy Policy")

        if not version or not content:
            return Response({"error": "Version and content are required."}, status=status.HTTP_400_BAD_REQUEST)

        PrivacyPolicy.objects.filter(is_active=True).update(is_active=False)

        policy, created = PrivacyPolicy.objects.update_or_create(
            version=version,
            defaults={
                "title": title,
                "content": content,
                "is_active": True,
                "published_at": timezone.now(),
                "published_by": request.user,
            },
        )
        return Response(PrivacyPolicySerializer(policy).data, status=status.HTTP_201_CREATED)


class NeedsReconsentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin permission required."}, status=status.HTTP_403_FORBIDDEN)

        active_policy = PrivacyPolicy.objects.filter(is_active=True).first()
        if not active_policy:
            return Response({"active_policy": None, "pending_users_count": 0, "pending_users": []})

        consented_user_ids = PolicyConsent.objects.filter(policy=active_policy).values_list("user_id", flat=True)
        pending_users = User.objects.exclude(id__in=consented_user_ids).filter(is_active=True)

        return Response({
            "active_policy_version": active_policy.version,
            "total_pending_count": pending_users.count(),
            "sample_pending_users": list(pending_users.values("id", "email", "full_name")[:50]),
        })


class ConsentPrivacyPolicyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        policy_id = request.data.get("policy_id")
        policy = None
        if policy_id:
            policy = PrivacyPolicy.objects.filter(id=policy_id).first()
        else:
            policy = PrivacyPolicy.objects.filter(is_active=True).first()

        if not policy:
            return Response({"error": "No active policy to consent to."}, status=status.HTTP_400_BAD_REQUEST)

        ip = request.META.get("HTTP_X_FORWARDED_FOR", request.META.get("REMOTE_ADDR", ""))
        consent, _ = PolicyConsent.objects.update_or_create(
            user=request.user,
            policy=policy,
            defaults={"ip_address": ip[:45] if ip else None, "consented_at": timezone.now()},
        )

        request.user.consent_policy_version = policy.version
        request.user.save(update_fields=["consent_policy_version"])

        return Response({"success": True, "consented_version": policy.version}, status=status.HTTP_200_OK)


class AdminDashboardView(APIView):
    """Comprehensive admin dashboard with key metrics and recent activity."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != Role.ADMINISTRATOR:
            return Response({"error": "Admin permission required."}, status=status.HTTP_403_FORBIDDEN)

        # User metrics
        total_users = User.objects.count()
        active_users = User.objects.filter(is_active=True).count()
        verified_users = User.objects.filter(email_verified=True).count()
        
        users_by_role = {
            "residents": User.objects.filter(role=Role.RESIDENT).count(),
            "collectors": User.objects.filter(role=Role.COLLECTOR).count(),
            "authorities": User.objects.filter(role=Role.AUTHORITY).count(),
            "recyclers": User.objects.filter(role=Role.RECYCLER).count(),
            "businesses": User.objects.filter(role=Role.BUSINESS).count(),
            "admins": User.objects.filter(role=Role.ADMINISTRATOR).count(),
        }

        # Waste request metrics
        total_requests = WasteRequest.objects.count()
        pending_requests = WasteRequest.objects.filter(status=WasteRequest.Status.PENDING).count()
        in_progress_requests = WasteRequest.objects.filter(status=WasteRequest.Status.ASSIGNED).count()
        completed_requests = WasteRequest.objects.filter(status=WasteRequest.Status.COLLECTED).count()
        
        total_weight_kg = WasteRequest.objects.filter(status=WasteRequest.Status.COLLECTED).aggregate(
            total=Sum("actual_weight_kg")
        )["total"] or 0

        # Collection assignment metrics
        active_assignments = CollectionAssignment.objects.filter(
            status__in=[CollectionAssignment.Status.ASSIGNED, CollectionAssignment.Status.IN_PROGRESS]
        ).count()
        completed_assignments = CollectionAssignment.objects.filter(
            status=CollectionAssignment.Status.COMPLETED
        ).count()

        # Report metrics
        total_reports = IllegalDumpingReport.objects.count()
        pending_reports = IllegalDumpingReport.objects.filter(
            status__in=[IllegalDumpingReport.Status.SUBMITTED, IllegalDumpingReport.Status.UNDER_INVESTIGATION]
        ).count()
        resolved_reports = IllegalDumpingReport.objects.filter(status=IllegalDumpingReport.Status.RESOLVED).count()

        # Verification metrics
        pending_verifications = CollectorVerification.objects.filter(
            status=CollectorVerification.Status.PENDING
        ).count()
        approved_verifications = CollectorVerification.objects.filter(
            status=CollectorVerification.Status.APPROVED
        ).count()
        rejected_verifications = CollectorVerification.objects.filter(
            status=CollectorVerification.Status.REJECTED
        ).count()

        # Financial metrics
        total_revenue = Payment.objects.filter(status=Payment.Status.SUCCESSFUL).aggregate(
            total=Sum("amount")
        )["total"] or 0
        
        total_payouts = Payout.objects.filter(status=Payout.Status.PROCESSED).aggregate(
            total=Sum("amount")
        )["total"] or 0

        pending_payouts = Payout.objects.filter(status=Payout.Status.PENDING).count()

        # Rewards metrics
        total_points_awarded = PointTransaction.objects.filter(points__gt=0).aggregate(
            total=Sum("points")
        )["total"] or 0

        total_points_redeemed = PointTransaction.objects.filter(points__lt=0).aggregate(
            total=Sum("points")
        )["total"] or 0

        # Zone metrics
        total_zones = Zone.objects.count()
        active_zones = Zone.objects.filter(is_active=True).count()

        # Recent activity (last 7 days)
        seven_days_ago = timezone.now() - timezone.timedelta(days=7)
        new_users_week = User.objects.filter(date_joined__gte=seven_days_ago).count()
        new_requests_week = WasteRequest.objects.filter(created_at__gte=seven_days_ago).count()
        new_reports_week = IllegalDumpingReport.objects.filter(created_at__gte=seven_days_ago).count()

        # Recent users
        recent_users = User.objects.order_by("-date_joined")[:5]
        recent_users_data = [
            {
                "id": u.id,
                "email": u.email,
                "full_name": u.full_name,
                "role": u.role,
                "created_at": u.date_joined.isoformat(),
            }
            for u in recent_users
        ]

        # Recent verifications needing attention
        pending_verifications_list = CollectorVerification.objects.filter(
            status=CollectorVerification.Status.PENDING
        ).order_by("-created_at")[:5]
        
        pending_verifications_data = [
            {
                "id": v.id,
                "collector_id": v.collector.id,
                "collector_email": v.collector.email,
                "collector_name": v.collector.full_name,
                "created_at": v.created_at.isoformat(),
            }
            for v in pending_verifications_list
        ]

        return Response({
            "users": {
                "total": total_users,
                "active": active_users,
                "verified": verified_users,
                "by_role": users_by_role,
                "new_this_week": new_users_week,
            },
            "waste_requests": {
                "total": total_requests,
                "pending": pending_requests,
                "in_progress": in_progress_requests,
                "completed": completed_requests,
                "total_weight_kg": float(total_weight_kg),
                "new_this_week": new_requests_week,
            },
            "collections": {
                "active_assignments": active_assignments,
                "completed_assignments": completed_assignments,
            },
            "reports": {
                "total": total_reports,
                "pending": pending_reports,
                "resolved": resolved_reports,
                "resolution_rate": round((resolved_reports / total_reports * 100), 1) if total_reports > 0 else 0.0,
                "new_this_week": new_reports_week,
            },
            "verifications": {
                "pending": pending_verifications,
                "approved": approved_verifications,
                "rejected": rejected_verifications,
            },
            "financials": {
                "total_revenue_ugx": float(total_revenue),
                "total_payouts_ugx": float(total_payouts),
                "net_margin_ugx": float(total_revenue) - float(total_payouts),
                "pending_payouts": pending_payouts,
                "currency": "UGX",
            },
            "rewards": {
                "total_points_awarded": total_points_awarded,
                "total_points_redeemed": abs(total_points_redeemed) if total_points_redeemed else 0,
            },
            "zones": {
                "total": total_zones,
                "active": active_zones,
            },
            "recent_activity": {
                "recent_users": recent_users_data,
                "pending_verifications": pending_verifications_data,
            },
        })
