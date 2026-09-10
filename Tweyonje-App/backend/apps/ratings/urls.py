from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import IncidentReportViewSet, RatingViewSet, UserSuspensionViewSet

router = DefaultRouter()
router.register("reviews", RatingViewSet, basename="rating")
router.register("incidents", IncidentReportViewSet, basename="incident")
router.register("suspensions", UserSuspensionViewSet, basename="suspension")

urlpatterns = [
    path("", include(router.urls)),
]
