from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import IllegalDumpingReportViewSet

router = DefaultRouter()
router.register("", IllegalDumpingReportViewSet, basename="report")

urlpatterns = [
    path("", include(router.urls)),
]
