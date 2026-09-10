from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AdminDashboardView,
    AdminUsersApi,
    CollectorVerificationViewSet,
    ConsentPrivacyPolicyView,
    NeedsReconsentView,
    PrivacyPolicyViewSet,
    PublishPrivacyPolicyView,
    SystemSettingViewSet,
    ZoneViewSet,
)

router = DefaultRouter()
router.register("zones", ZoneViewSet, basename="zone")
router.register("verifications", CollectorVerificationViewSet, basename="collector-verification")
router.register("policies", PrivacyPolicyViewSet, basename="privacy-policy")
router.register("settings", SystemSettingViewSet, basename="system-setting")

urlpatterns = [
    path("dashboard/", AdminDashboardView.as_view(), name="admin-dashboard"),
    path("users/", AdminUsersApi.as_view(), name="admin-users"),
    path("privacy-policy/publish/", PublishPrivacyPolicyView.as_view(), name="privacy-policy-publish"),
    path("privacy-policy/needs-reconsent/", NeedsReconsentView.as_view(), name="privacy-policy-needs-reconsent"),
    path("privacy-policy/consent/", ConsentPrivacyPolicyView.as_view(), name="privacy-policy-consent"),
    path("", include(router.urls)),
]
