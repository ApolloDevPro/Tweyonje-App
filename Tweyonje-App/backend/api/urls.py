from django.urls import include, path

urlpatterns = [
    path("auth/", include("apps.accounts.urls")),
    path("profiles/", include("apps.profiles.urls")),
    path("waste-requests/", include("apps.waste_requests.urls")),
    path("collections/", include("apps.collections.urls")),
    path("tracking/", include("apps.tracking.urls")),
    path("reports/", include("apps.reports.urls")),
    path("notifications/", include("apps.notifications.urls")),
    path("payments/", include("apps.payments.urls")),
    path("recycling/", include("apps.recycling.urls")),
    path("rewards/", include("apps.rewards.urls")),
    path("ratings/", include("apps.ratings.urls")),
    path("admin/", include("apps.platform_admin.urls")),
    path("analytics/", include("apps.analytics.urls")),
    path("routing/", include("apps.routing.urls")),
    path("ai/", include("apps.ai.urls")),
    path("support/", include("apps.support.urls")),
    path("chat/", include("apps.chat.urls")),
    path("security/", include("apps.security.urls")),
    path("localization/", include("apps.localization.urls")),
]
