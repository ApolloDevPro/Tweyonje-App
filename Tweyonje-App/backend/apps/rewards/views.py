from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role
from .models import EcoWallet, RedemptionRequest, RewardItem, RewardTier
from .serializers import (
    EcoWalletSerializer,
    RedemptionRequestSerializer,
    RewardItemSerializer,
    RewardTierSerializer,
)
from .services import redeem_reward_points


class EcoWalletView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        wallet, _ = EcoWallet.objects.get_or_create(user=request.user)
        return Response(EcoWalletSerializer(wallet).data)


class RewardTierViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = RewardTier.objects.filter(is_active=True)
    serializer_class = RewardTierSerializer


class RewardItemViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.AllowAny]
    queryset = RewardItem.objects.filter(is_active=True)
    serializer_class = RewardItemSerializer
    filterset_fields = ["category"]
    search_fields = ["title", "description"]

    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def redeem(self, request, pk=None):
        item = self.get_object()
        success, result = redeem_reward_points(user=request.user, reward_item=item)
        if not success:
            return Response({"error": result}, status=status.HTTP_400_BAD_REQUEST)
        return Response(RedemptionRequestSerializer(result).data, status=status.HTTP_201_CREATED)


class RedemptionRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RedemptionRequestSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return RedemptionRequest.objects.all()
        return RedemptionRequest.objects.filter(user=user)

    @action(detail=True, methods=["post"])
    def update_status(self, request, pk=None):
        user = request.user
        if user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        redemption = self.get_object()
        new_status = request.data.get("status")
        notes = request.data.get("notes", "")

        if new_status in RedemptionRequest.Status.values:
            redemption.status = new_status
            if notes:
                redemption.notes = notes
            redemption.save(update_fields=["status", "notes", "updated_at"])
            return Response(RedemptionRequestSerializer(redemption).data)

        return Response({"error": "Invalid status."}, status=status.HTTP_400_BAD_REQUEST)
