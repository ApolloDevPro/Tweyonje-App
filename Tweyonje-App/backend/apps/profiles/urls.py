from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    MyProfileView,
    NotificationPreferenceView,
    SiteViewSet,
    VehicleViewSet,
)

router = DefaultRouter()
router.register("vehicles", VehicleViewSet, basename="vehicle")
router.register("sites", SiteViewSet, basename="site")

urlpatterns = [
    path("me/", MyProfileView.as_view(), name="profile-me"),
    path("notification-preferences/", NotificationPreferenceView.as_view(), name="profile-notification-preferences"),
    path("", include(router.urls)),
]
