from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    RecurringScheduleViewSet,
    WasteCategoryViewSet,
    WasteRequestViewSet,
)

router = DefaultRouter()
router.register("categories", WasteCategoryViewSet, basename="waste-category")
router.register("schedules", RecurringScheduleViewSet, basename="waste-schedule")
router.register("", WasteRequestViewSet, basename="waste-request")

urlpatterns = [
    path("", include(router.urls)),
]
