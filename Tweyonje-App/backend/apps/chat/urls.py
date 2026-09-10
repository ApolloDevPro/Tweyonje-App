from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ChatConversationViewSet

router = DefaultRouter()
router.register("conversations", ChatConversationViewSet, basename="chat-conversation")

urlpatterns = [
    path("", include(router.urls)),
]