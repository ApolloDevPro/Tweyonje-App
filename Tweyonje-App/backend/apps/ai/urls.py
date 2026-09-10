from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ClassificationLogViewSet, ClassifyWasteImageView

router = DefaultRouter()
router.register("history", ClassificationLogViewSet, basename="ai-history")

urlpatterns = [
    path("classify-waste/", ClassifyWasteImageView.as_view(), name="ai-classify-waste"),
    path("", include(router.urls)),
]
