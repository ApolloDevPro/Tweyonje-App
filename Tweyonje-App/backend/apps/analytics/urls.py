from django.urls import path

from .views import (
    AnalyticsCollectionsView,
    AnalyticsFinancialsView,
    AnalyticsHotspotsView,
    AnalyticsOverviewView,
)
from .views_timeseries import (
    CollectionsTrendView,
    CollectorPerformanceTrendView,
    PaymentSuccessRateTrendView,
    UserGrowthTrendView,
    WasteCategoryTrendView,
)

urlpatterns = [
    path("overview/", AnalyticsOverviewView.as_view(), name="analytics-overview"),
    path("hotspots/", AnalyticsHotspotsView.as_view(), name="analytics-hotspots"),
    path("collections/", AnalyticsCollectionsView.as_view(), name="analytics-collections"),
    path("financials/", AnalyticsFinancialsView.as_view(), name="analytics-financials"),
    
    # Time-series endpoints
    path("trends/collections/", CollectionsTrendView.as_view(), name="trends-collections"),
    path("trends/collector-performance/", CollectorPerformanceTrendView.as_view(), name="trends-collector"),
    path("trends/payment-success/", PaymentSuccessRateTrendView.as_view(), name="trends-payments"),
    path("trends/user-growth/", UserGrowthTrendView.as_view(), name="trends-users"),
    path("trends/waste-categories/", WasteCategoryTrendView.as_view(), name="trends-categories"),
]
