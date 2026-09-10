from datetime import datetime

from django.utils import timezone
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from core.models import Role
from .models import RoutePlan
from .serializers import RoutePlanSerializer
from .services import optimize_collector_daily_route


class RoutePlanViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RoutePlanSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return RoutePlan.objects.all()
        return RoutePlan.objects.filter(collector=user)

    @action(detail=False, methods=["post"])
    def optimize(self, request):
        user = request.user
        date_str = request.data.get("date")
        target_date = timezone.now().date()
        if date_str:
            target_date = datetime.strptime(date_str, "%Y-%m-%d").date()

        collector_user = user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY) and request.data.get("collector_id"):
            from django.contrib.auth import get_user_model
            User = get_user_model()
            collector_user = User.objects.filter(id=request.data["collector_id"]).first() or user

        route_plan = optimize_collector_daily_route(collector=collector_user, target_date=target_date)
        if not route_plan:
            return Response(
                {"detail": "No pending jobs found for route optimization on this date."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(RoutePlanSerializer(route_plan).data, status=status.HTTP_200_OK)
