from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CollectionAssignmentViewSet,
    CollectionSlotViewSet,
    CollectorDashboardView,
    CollectorShiftViewSet,
)

router = DefaultRouter()
router.register("slots", CollectionSlotViewSet, basename="collection-slot")
router.register("assignments", CollectionAssignmentViewSet, basename="collection-assignment")
router.register("shifts", CollectorShiftViewSet, basename="collector-shift")

urlpatterns = [
    path("dashboard/", CollectorDashboardView.as_view(), name="collector-dashboard"),
    path("", include(router.urls)),
]
