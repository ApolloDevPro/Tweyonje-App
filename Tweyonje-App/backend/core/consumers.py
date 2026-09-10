"""WebSocket consumer backing ``ws://<host>/ws/``.

Clients authenticate with a JWT access token passed as the ``token`` query
parameter and then subscribe to scoped event streams, e.g.::

    {"type": "subscribe", "data": {"type": "collection", "id": "<uuid>"}}
    {"type": "unsubscribe", "data": {"type": "collection", "id": "<uuid>"}}

The server pushes messages shaped like
``{"type": "collection_update", "data": {...}, "timestamp": ...}``.
"""

from __future__ import annotations

import logging
import urllib.parse

from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser

from core import realtime

logger = logging.getLogger(__name__)


class WebSocketSubscriber(AsyncJsonWebsocketConsumer):
    """Generic authenticated pub/sub endpoint for all realtime scopes."""

    subscriptions: set

    async def connect(self):
        self.user = self.scope.get("user", AnonymousUser())
        if not self.user or not getattr(self.user, "is_authenticated", False):
            await self.close(code=4401)
            return
        self.subscriptions = set()
        await self.accept()
        await self._send_event("connected", {"user_id": str(self.user.pk)})

    async def disconnect(self, code):
        for group in list(getattr(self, "subscriptions", set())):
            await self.channel_layer.group_discard(group, self.channel_name)
        self.subscriptions = set()

    async def receive_json(self, content, **kwargs):
        action = content.get("type")
        data = content.get("data") or {}
        if action == "ping":
            await self._send_event("pong", {})
            return
        if action not in ("subscribe", "unsubscribe"):
            await self._send_event("error", {"detail": f"Unknown action '{action}'."})
            return

        scope_type = str(data.get("type", "")).lower()
        raw_id = data.get("id")
        group_id = "marketplace" if scope_type == realtime.SCOPE_RECYCLING else str(raw_id or "")

        if scope_type not in realtime.SUPPORTED_SCOPES:
            await self._send_event("error", {"detail": f"Unsupported scope '{scope_type}'."})
            return
        if scope_type != realtime.SCOPE_RECYCLING and not group_id:
            await self._send_event("error", {"detail": "Missing subscription id."})
            return

        allowed = await self._can_access(scope_type, group_id)
        if not allowed:
            await self._send_event("error", {"detail": "You do not have access to this stream."})
            return

        group = realtime.group_name(scope_type, group_id)
        if action == "subscribe":
            if group not in self.subscriptions:
                self.subscriptions.add(group)
                await self.channel_layer.group_add(group, self.channel_name)
            await self._send_event("subscribed", {"scope": scope_type, "id": group_id})
        else:
            if group in self.subscriptions:
                self.subscriptions.discard(group)
                await self.channel_layer.group_discard(group, self.channel_name)
            await self._send_event("unsubscribed", {"scope": scope_type, "id": group_id})

    
    # Channel layer handler (dispatched via {"type": "push.event", ...})
    async def push_event(self, message):
        await self._send_event(message["event_type"], message.get("data", {}))

    
    async def _send_event(self, event_type: str, data: dict) -> None:
        from django.utils.timezone import now

        await self.send_json({"type": event_type, "data": data, "timestamp": int(now().timestamp() * 1000)})

    async def _can_access(self, scope_type: str, object_id: str) -> bool:
        from asgiref.sync import sync_to_async

        try:
            checker = SCOPE_ACCESS_CHECKS[scope_type]
            return await sync_to_async(lambda: checker(self.user, object_id))()
        except Exception:
            logger.exception("Realtime access check failed (%s/%s)", scope_type, object_id)
            return False



# Per-scope authorization helpers (sync; run inside the consumer thread pool)


def _user_is_privileged(user) -> bool:
    role = getattr(user, "role", "")
    return user.is_staff or role in ("AUTHORITY", "ADMINISTRATOR")


def _can_access_collection(user, request_id: str) -> bool:
    from apps.collections.models import CollectionAssignment
    from apps.waste_requests.models import WasteRequest

    if WasteRequest.objects.filter(id=request_id, user=user).exists():
        return True
    if CollectionAssignment.objects.filter(waste_request_id=request_id, collector=user).exists():
        return True
    return _user_is_privileged(user)


def _can_access_payment(user, payment_id: str) -> bool:
    from apps.payments.models import Payment

    return Payment.objects.filter(id=payment_id, user=user).exists() or _user_is_privileged(user)


def _can_access_support(user, ticket_id: str) -> bool:
    from apps.support.models import SupportTicket

    return (
        SupportTicket.objects.filter(id=ticket_id, user=user).exists()
        or SupportTicket.objects.filter(id=ticket_id, assigned_to=user).exists()
        or _user_is_privileged(user)
    )


def _can_access_assignment(user, assignment_id: str) -> bool:
    from apps.collections.models import CollectionAssignment

    assignment = CollectionAssignment.objects.filter(id=assignment_id).first()
    if not assignment:
        return False
    return (
        assignment.collector_id == user.pk
        or assignment.waste_request.user_id == user.pk
        or _user_is_privileged(user)
    )


def _can_access_zone(user, zone_id: str) -> bool:
    return _user_is_privileged(user)


def _can_access_recycling(user, _group_id: str) -> bool:
    return True


def _can_access_chat(user, conversation_id: str) -> bool:
    from apps.chat.models import ChatConversation
    
    conversation = ChatConversation.objects.filter(id=conversation_id).first()
    if not conversation:
        return False
    return (
        conversation.waste_request.user_id == user.pk
        or conversation.collector_id == user.pk
        or _user_is_privileged(user)
    )


SCOPE_ACCESS_CHECKS = {
    realtime.SCOPE_COLLECTION: _can_access_collection,
    realtime.SCOPE_ASSIGNMENT: _can_access_assignment,
    realtime.SCOPE_PAYMENT: _can_access_payment,
    realtime.SCOPE_SUPPORT: _can_access_support,
    realtime.SCOPE_RECYCLING: _can_access_recycling,
    realtime.SCOPE_ZONE: _can_access_zone,
    realtime.SCOPE_CHAT: _can_access_chat,
}
