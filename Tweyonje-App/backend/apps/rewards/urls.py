from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    EcoWalletView,
    RedemptionRequestViewSet,
    RewardItemViewSet,
    RewardTierViewSet,
)

router = DefaultRouter()
router.register("tiers", RewardTierViewSet, basename="reward-tier")
router.register("items", RewardItemViewSet, basename="reward-item")
router.register("redemptions", RedemptionRequestViewSet, basename="redemption-request")

urlpatterns = [
    path("wallet/", EcoWalletView.as_view(), name="rewards-wallet"),
    path("", include(router.urls)),
]
