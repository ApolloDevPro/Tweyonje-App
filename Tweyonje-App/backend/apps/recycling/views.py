from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from core.models import Role
from .models import (
    MarketplaceListing,
    RecyclableMaterial,
    RecyclingCenter,
    RecyclingTradeIn,
)
from .serializers import (
    MarketplaceListingSerializer,
    RecyclableMaterialSerializer,
    RecyclingCenterSerializer,
    RecyclingTradeInSerializer,
)


class RecyclableMaterialViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = RecyclableMaterial.objects.filter(is_active=True)
    serializer_class = RecyclableMaterialSerializer
    filterset_fields = ["material_type"]


class RecyclingCenterViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = RecyclingCenter.objects.filter(is_active=True)
    serializer_class = RecyclingCenterSerializer
    filterset_fields = ["zone"]
    search_fields = ["name", "address"]


class MarketplaceListingViewSet(viewsets.ModelViewSet):
    serializer_class = MarketplaceListingSerializer
    filterset_fields = ["material", "status"]
    search_fields = ["title", "description", "location_address"]
    ordering_fields = ["created_at", "price_ugx", "weight_kg"]

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        if self.action == "list":
            return MarketplaceListing.objects.filter(status=MarketplaceListing.Status.AVAILABLE)
        return MarketplaceListing.objects.all()

    def perform_create(self, serializer):
        serializer.save(seller=self.request.user)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def reserve(self, request, pk=None):
        listing = self.get_object()
        if listing.status != MarketplaceListing.Status.AVAILABLE:
            return Response({"error": "Listing is no longer available."}, status=status.HTTP_400_BAD_REQUEST)
        listing.status = MarketplaceListing.Status.RESERVED
        listing.save(update_fields=["status", "updated_at"])
        return Response(MarketplaceListingSerializer(listing).data)

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def mark_sold(self, request, pk=None):
        listing = self.get_object()
        if listing.seller != request.user and request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Only seller can mark as sold."}, status=status.HTTP_403_FORBIDDEN)
        listing.status = MarketplaceListing.Status.SOLD
        listing.save(update_fields=["status", "updated_at"])
        return Response(MarketplaceListingSerializer(listing).data)


class RecyclingTradeInViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RecyclingTradeInSerializer
    filterset_fields = ["status", "center", "material"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY, Role.RECYCLER):
            return RecyclingTradeIn.objects.all()
        return RecyclingTradeIn.objects.filter(user=user)

    def perform_create(self, serializer):
        trade_in = serializer.save(user=self.request.user)
        # Calculate payment amount and eco-points
        mat = trade_in.material
        weight = float(trade_in.weight_kg)
        amount = weight * float(mat.price_per_kg)
        points = int(weight * float(mat.point_multiplier) * 10)

        trade_in.amount_paid_ugx = amount
        trade_in.eco_points_earned = points
        # Trade-ins start PENDING and only earn points after verification by
        # a recycling center / administrator.
        trade_in.status = RecyclingTradeIn.Status.PENDING
        trade_in.save(update_fields=["amount_paid_ugx", "eco_points_earned", "status"])

    @action(detail=True, methods=["post"])
    def verify(self, request, pk=None):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY, Role.RECYCLER):
            return Response(
                {"error": "Only recycling staff/administrators can verify trade-ins."},
                status=status.HTTP_403_FORBIDDEN,
            )
        trade_in = self.get_object()
        if trade_in.status == RecyclingTradeIn.Status.COMPLETED:
            return Response(
                {"error": "Trade-in already verified."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        trade_in.status = RecyclingTradeIn.Status.COMPLETED
        trade_in.save(update_fields=["status"])

        # Award points idempotently (guarded by the trade-in source).
        from apps.rewards.services import award_eco_points
        award_eco_points(
            user=trade_in.user,
            points=trade_in.eco_points_earned,
            transaction_type="EARNED_RECYCLING",
            source_id=str(trade_in.id),
            description=(
                f"Recycled {trade_in.weight_kg}kg of {trade_in.material.name}"
            ),
        )
        return Response(RecyclingTradeInSerializer(trade_in).data)
