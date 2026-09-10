from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    DisputeExportView,
    DisputeMetricsView,
    DisputeViewSet,
    SupportTicketViewSet,
)

router = DefaultRouter()
router.register("tickets", SupportTicketViewSet, basename="support-ticket")
router.register("disputes", DisputeViewSet, basename="dispute")

urlpatterns = [
    path("disputes/metrics/", DisputeMetricsView.as_view(), name="dispute-metrics"),
    path("disputes/export/", DisputeExportView.as_view(), name="dispute-export"),
    path("", include(router.urls)),
]
