from django.contrib.auth import get_user_model
from django.db.models import Avg, Count, Sum
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role, Zone
from apps.collections.models import CollectionAssignment
from apps.payments.models import Payment, Payout
from apps.reports.models import IllegalDumpingReport
from apps.rewards.models import EcoWallet, PointTransaction
from apps.waste_requests.models import WasteCategory, WasteRequest

User = get_user_model()


class AnalyticsOverviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        total_users = User.objects.count()
        total_requests = WasteRequest.objects.count()
        collected_requests = WasteRequest.objects.filter(status=WasteRequest.Status.COLLECTED).count()
        total_weight_kg = WasteRequest.objects.filter(status=WasteRequest.Status.COLLECTED).aggregate(
            total=Sum("actual_weight_kg")
        )["total"] or 0

        total_reports = IllegalDumpingReport.objects.count()
        resolved_reports = IllegalDumpingReport.objects.filter(status=IllegalDumpingReport.Status.RESOLVED).count()

        total_eco_points = PointTransaction.objects.filter(points__gt=0).aggregate(
            total=Sum("points")
        )["total"] or 0

        return Response({
            "users": {
                "total": total_users,
                "residents": User.objects.filter(role=Role.RESIDENT).count(),
                "collectors": User.objects.filter(role=Role.COLLECTOR).count(),
                "recyclers": User.objects.filter(role=Role.RECYCLER).count(),
            },
            "collections": {
                "total_requests": total_requests,
                "completed": collected_requests,
                "pending": WasteRequest.objects.filter(status=WasteRequest.Status.PENDING).count(),
                "total_weight_kg": float(total_weight_kg),
            },
            "environmental_reports": {
                "total": total_reports,
                "resolved": resolved_reports,
                "resolution_rate": round((resolved_reports / total_reports * 100), 1) if total_reports > 0 else 0.0,
            },
            "rewards": {
                "total_points_distributed": total_eco_points,
            },
        })


class AnalyticsHotspotsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        # Hotspot clusters by Zone for illegal dumping and collection density
        zones = Zone.objects.all()
        hotspot_data = []

        for z in zones:
            dumping_count = IllegalDumpingReport.objects.filter(zone=z).count()
            dumping_open = IllegalDumpingReport.objects.filter(
                zone=z,
                status__in=[
                    IllegalDumpingReport.Status.SUBMITTED,
                    IllegalDumpingReport.Status.UNDER_INVESTIGATION,
                ],
            ).count()
            waste_count = WasteRequest.objects.filter(zone=z).count()

            # Extract GPS sample coords
            sample_coords = list(
                IllegalDumpingReport.objects.filter(zone=z, latitude__isnull=False, longitude__isnull=False)
                .values("latitude", "longitude", "severity", "status")[:20]
            )

            hotspot_data.append({
                "zone_id": z.id,
                "zone_name": z.name,
                "zone_code": z.code,
                "illegal_dumping_total": dumping_count,
                "illegal_dumping_open": dumping_open,
                "total_waste_requests": waste_count,
                "severity_score": (dumping_open * 2) + waste_count,
                "points": sample_coords,
            })

        hotspot_data.sort(key=lambda x: x["severity_score"], reverse=True)
        return Response({"hotspots": hotspot_data})


class AnalyticsCollectionsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        # Breakdown of waste collected by category
        categories = WasteCategory.objects.all()
        breakdown = []

        for cat in categories:
            stats = WasteRequest.objects.filter(
                category=cat,
                status=WasteRequest.Status.COLLECTED,
            ).aggregate(
                total_count=Count("id"),
                total_weight=Sum("actual_weight_kg"),
            )
            breakdown.append({
                "category_id": cat.id,
                "category_name": cat.name,
                "collections_count": stats["total_count"] or 0,
                "total_weight_kg": float(stats["total_weight"] or 0),
            })

        return Response({"category_breakdown": breakdown})


class AnalyticsFinancialsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        total_collected = Payment.objects.filter(status=Payment.Status.SUCCESSFUL).aggregate(
            total=Sum("amount")
        )["total"] or 0

        total_payouts = Payout.objects.filter(status=Payout.Status.PROCESSED).aggregate(
            total=Sum("amount")
        )["total"] or 0

        # By method
        methods = Payment.objects.filter(status=Payment.Status.SUCCESSFUL).values("method").annotate(
            count=Count("id"),
            total_amount=Sum("amount"),
        )

        return Response({
            "gross_revenue_ugx": float(total_collected),
            "total_collector_payouts_ugx": float(total_payouts),
            "net_margin_ugx": float(total_collected) - float(total_payouts),
            "payment_methods_breakdown": list(methods),
            "currency": "UGX",
        })
