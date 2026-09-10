"""
ASGI config for the Tweyonje backend.

Serves HTTP (Django views / DRF) and WebSocket connections (realtime
updates via Django Channels) from a single application.
"""

import os
import urllib.parse

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter

from core.routing import websocket_urlpatterns


class JWTAuthMiddleware:
    """Resolves a ``?token=<jwt>`` query parameter to a user for Channels."""

    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        scope = dict(scope)
        query_string = scope.get("query_string", b"")
        params = urllib.parse.parse_qsl(query_string.decode("utf-8"))
        token = dict(params).get("token")
        if token:
            scope["user"] = await self._resolve_user(token)
        return await self.inner(scope, receive, send)

    @staticmethod
    async def _resolve_user(token: str):
        from asgiref.sync import sync_to_async
        from django.contrib.auth.models import AnonymousUser
        from rest_framework_simplejwt.authentication import JWTAuthentication
        from rest_framework_simplejwt.exceptions import TokenError
        from rest_framework_simplejwt.tokens import UntypedToken

        try:
            UntypedToken(token)
        except TokenError:
            return AnonymousUser()

        try:
            validated = JWTAuthentication().get_validated_token(token)
            return await sync_to_async(JWTAuthentication().get_user)(validated)
        except Exception:
            return AnonymousUser()


application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": JWTAuthMiddleware(URLRouter(websocket_urlpatterns)),
    }
)
