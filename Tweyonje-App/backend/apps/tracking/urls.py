from django.urls import path

from .views import GetCollectorLocationView, UpdateLiveLocationView

urlpatterns = [
    path("live/", UpdateLiveLocationView.as_view(), name="tracking-update-live"),
    path("collector/<uuid:assignment_id>/", GetCollectorLocationView.as_view(), name="tracking-get-collector"),
]
