"""Real-time helpers built on Django Channels.

Provides a thin, dependency-tolerant API for pushing events to WebSocket
groups. Every function degrades gracefully when no channel layer is
configured so callers never need to guard their code paths.
"""

from __future__ import annotations

import logging

from django.conf import settings

logger = logging.getLogger(__name__)

# Scope types understood by core.consumers.WebSocketSubscriber.
SCOPE_COLLECTION = "collection"
SCOPE_ASSIGNMENT = "assignment"
SCOPE_PAYMENT = "payment"
SCOPE_SUPPORT = "support"
SCOPE_RECYCLING = "recycling"
SCOPE_ZONE = "zone"
SCOPE_CHAT = "chat"

SUPPORTED_SCOPES = {
    SCOPE_COLLECTION,
    SCOPE_ASSIGNMENT,
    SCOPE_PAYMENT,
    SCOPE_SUPPORT,
    SCOPE_RECYCLING,
    SCOPE_ZONE,
    SCOPE_CHAT,
}


def _channel_layer():
    from channels.layers import get_channel_layer

    return get_channel_layer()


def group_name(scope_type: str, group_id) -> str:
    return f"{scope_type}.{group_id}"


def broadcast_event(scope_type: str, group_id, event_type: str, data: dict) -> None:
    """Send ``event_type`` with ``data`` to everyone subscribed to the scope."""
    try:
        layer = _channel_layer()
        if layer is None:
            return
        from asgiref.sync import async_to_sync

        async_to_sync(layer.group_send)(
            group_name(scope_type, group_id),
            {"type": "push.event", "event_type": event_type, "data": data},
        )
    except Exception:  # pragma: no cover - realtime must never break requests
        logger.exception("Failed to broadcast %s to %s.%s", event_type, scope_type, group_id)


def notify_request_update(waste_request) -> None:
    from collections import defaultdict

    payload = {
        "request_id": str(waste_request.id),
        "status": waste_request.status,
        "payment_status": getattr(waste_request, "payment_status", None),
        "updated_at": str(getattr(waste_request, "updated_at", "")),
    }
    assignments = defaultdict(list)
    from apps.collections.models import CollectionAssignment

    for assignment in CollectionAssignment.objects.filter(waste_request=waste_request):
        payload["assignment_status"] = assignment.status
        broadcast_event(SCOPE_ASSIGNMENT, assignment.id, "assignment_update", payload)
        assignments[assignment.status].append(str(assignment.id))
    if assignments:
        payload["assignments"] = dict(assignments)
    broadcast_event(SCOPE_COLLECTION, waste_request.id, "collection_update", payload)


def notify_payment_update(payment) -> None:
    broadcast_event(
        SCOPE_PAYMENT,
        payment.id,
        "payment_update",
        {
            "payment_id": str(payment.id),
            "reference_id": payment.reference_id,
            "status": payment.status,
            "amount": float(payment.amount),
            "currency": payment.currency,
            "method": payment.method,
            "transaction_id": payment.transaction_id,
            "waste_request_id": str(payment.waste_request_id) if payment.waste_request_id else None,
        },
    )


def notify_support_update(ticket) -> None:
    broadcast_event(
        SCOPE_SUPPORT,
        ticket.id,
        "support_update",
        {
            "ticket_id": str(ticket.id),
            "ticket_number": ticket.ticket_number,
            "status": ticket.status,
            "is_escalated": ticket.is_escalated,
        },
    )


def notify_recycling_offer(listing) -> None:
    broadcast_event(
        SCOPE_RECYCLING,
        "marketplace",
        "recycling_offer",
        {
            "listing_id": str(listing.id),
            "title": listing.title,
            "material_id": str(listing.material_id),
            "weight_kg": float(listing.weight_kg),
            "price_ugx": float(listing.price_ugx),
        },
    )


def notify_zone_update(zone) -> None:
    broadcast_event(
        SCOPE_ZONE,
        zone.id,
        "zone_update",
        {
            "zone_id": str(zone.id),
            "name": zone.name,
            "is_active": getattr(zone, "is_active", True),
        },
    )


def notify_chat_message(conversation, message) -> None:
    """Push a new chat message to both participants in the conversation."""
    broadcast_event(
        SCOPE_CHAT,
        conversation.id,
        "chat_message",
        {
            "conversation_id": str(conversation.id),
            "message_id": str(message.id),
            "sender_id": str(message.sender_id),
            "sender_name": message.sender.full_name,
            "content": message.content,
            "sent_at": message.created_at.isoformat(),
            "is_read": message.is_read,
        },
    )


def notify_chat_typing(conversation, user) -> None:
    """Indicate that a user is typing in the conversation."""
    broadcast_event(
        SCOPE_CHAT,
        conversation.id,
        "chat_typing",
        {
            "conversation_id": str(conversation.id),
            "user_id": str(user.id),
            "user_name": user.full_name,
        },
    )


def notify_collector_location(live_location) -> None:
    """Push a collector's GPS ping to every live assignment watching them."""
    from apps.collections.models import CollectionAssignment

    active_statuses = [
        CollectionAssignment.Status.ASSIGNED,
        CollectionAssignment.Status.EN_ROUTE,
        CollectionAssignment.Status.ARRIVED,
    ]
    assignments = CollectionAssignment.objects.filter(
        collector=live_location.user, status__in=active_statuses
    )
    for assignment in assignments:
        eta_minutes = None
        distance_km = None
        request = assignment.waste_request
        if request.latitude and request.longitude:
            from apps.tracking.serializers import calculate_haversine_distance_km

            distance_km = calculate_haversine_distance_km(
                float(live_location.latitude),
                float(live_location.longitude),
                float(request.latitude),
                float(request.longitude),
            )
            speed = float(live_location.speed_kmh or 20)
            if speed > 0:
                eta_minutes = round((distance_km / speed) * 60)
        broadcast_event(
            SCOPE_ASSIGNMENT,
            assignment.id,
            "location_update",
            {
                "request_id": str(request.id),
                "assignment_id": str(assignment.id),
                "collector_id": str(live_location.user_id),
                "latitude": float(live_location.latitude),
                "longitude": float(live_location.longitude),
                "heading": float(live_location.heading) if live_location.heading else None,
                "speed_kmh": float(live_location.speed_kmh) if live_location.speed_kmh else None,
                "distance_km": round(distance_km, 3) if distance_km is not None else None,
                "eta_minutes": max(eta_minutes or 2, 2),
                "recorded_at": str(live_location.last_updated),
            },
        )


def realtime_enabled() -> bool:
    return bool(getattr(settings, "CHANNEL_LAYERS", None))
