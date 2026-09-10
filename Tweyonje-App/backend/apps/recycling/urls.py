from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    MarketplaceListingViewSet,
    RecyclableMaterialViewSet,
    RecyclingCenterViewSet,
    RecyclingTradeInViewSet,
)

router = DefaultRouter()
router.register("materials", RecyclableMaterialViewSet, basename="recyclable-material")
router.register("centers", RecyclingCenterViewSet, basename="recycling-center")
router.register("marketplace", MarketplaceListingViewSet, basename="marketplace-listing")
router.register("trade-ins", RecyclingTradeInViewSet, basename="recycling-trade-in")

urlpatterns = [
    path("", include(router.urls)),
]
