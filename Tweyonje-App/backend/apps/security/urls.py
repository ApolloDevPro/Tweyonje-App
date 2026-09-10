from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import AuditLogViewSet, SecurityEventViewSet

router = DefaultRouter()
router.register("audit-logs", AuditLogViewSet, basename="audit-log")
router.register("events", SecurityEventViewSet, basename="security-event")

urlpatterns = [
    path("", include(router.urls)),
]
