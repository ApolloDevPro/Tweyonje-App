from django.contrib.auth import get_user_model
from django.db import models
from django.db.models import Avg, Count
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.serializers import UserSerializer
from core.models import Role
from .models import IncidentReport, Rating, UserSuspension
from .serializers import (
    IncidentReportSerializer,
    RatingSerializer,
    UserSuspensionSerializer,
)

User = get_user_model()


class RatingViewSet(viewsets.ModelViewSet):
    serializer_class = RatingSerializer
    filterset_fields = ["to_user", "score", "is_public"]

    def get_permissions(self):
        if self.action in ("list", "retrieve", "user_summary"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        return Rating.objects.filter(is_public=True)

    def perform_create(self, serializer):
        serializer.save(from_user=self.request.user)

    @action(detail=False, methods=["get"], url_path="user/(?P<user_id>[^/.]+)")
    def user_summary(self, request, user_id=None):
        ratings = Rating.objects.filter(to_user_id=user_id)
        stats = ratings.aggregate(avg_score=Avg("score"), total_count=Count("id"))
        return Response({
            "user_id": user_id,
            "average_rating": round(stats["avg_score"] or 0, 1),
            "total_reviews": stats["total_count"] or 0,
            "recent_reviews": RatingSerializer(ratings[:10], many=True).data,
        })

    @action(detail=False, methods=["get"])
    def lookup_collector(self, request):
        """Resolve a collector id from their email so a resident can rate them.

        GET /ratings/reviews/lookup_collector/?email=...&q=...
        """
        email = request.query_params.get("email", "").strip().lower()
        q = request.query_params.get("q", "").strip()
        user = request.user
        qs = User.objects.filter(role=Role.COLLECTOR)
        if email:
            qs = qs.filter(email__iexact=email)
        elif q:
            qs = qs.filter(
                (models.Q(email__icontains=q) | models.Q(full_name__icontains=q))
            )
        else:
            return Response({"results": []})
        return Response({
            "results": UserSerializer(qs[:10], many=True).data,
        })


class IncidentReportViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = IncidentReportSerializer
    filterset_fields = ["status", "category"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return IncidentReport.objects.all()
        return IncidentReport.objects.filter(reported_by=user)

    def perform_create(self, serializer):
        serializer.save(reported_by=self.request.user)


class UserSuspensionViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSuspensionSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return UserSuspension.objects.none()
        return UserSuspension.objects.all()

    def perform_create(self, serializer):
        suspension = serializer.save(issued_by=self.request.user)
        # Deactivate user
        target_user = suspension.user
        target_user.is_active = False
        target_user.save(update_fields=["is_active"])
