from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import RoutePlanViewSet

router = DefaultRouter()
router.register("plans", RoutePlanViewSet, basename="route-plan")

urlpatterns = [
    path("", include(router.urls)),
]
