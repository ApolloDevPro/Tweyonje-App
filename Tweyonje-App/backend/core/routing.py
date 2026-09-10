from django.urls import re_path

from .consumers import WebSocketSubscriber

websocket_urlpatterns = [
    re_path(r"^ws/$", WebSocketSubscriber.as_asgi()),
]
