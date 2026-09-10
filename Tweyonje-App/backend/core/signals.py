"""Signal receivers that push realtime events when domain objects change."""

from __future__ import annotations

import logging

from django.db.models.signals import post_save
from django.dispatch import receiver

from core import realtime
from core.realtime import notify_request_update

logger = logging.getLogger(__name__)


@receiver(post_save, sender="payments.Payment")
def payment_saved(sender, instance, **kwargs):
    realtime.notify_payment_update(instance)
    if instance.waste_request_id and instance.status in ("SUCCESSFUL", "FAILED", "REFUNDED"):
        from apps.waste_requests.models import WasteRequest

        request = WasteRequest.objects.filter(id=instance.waste_request_id).first()
        if request:
            notify_request_update(request)


@receiver(post_save, sender="collections.CollectionAssignment")
def assignment_saved(sender, instance, **kwargs):
    realtime.notify_request_update(instance.waste_request)


@receiver(post_save, sender="waste_requests.WasteRequest")
def waste_request_saved(sender, instance, **kwargs):
    notify_request_update(instance)


@receiver(post_save, sender="support.SupportTicket")
def support_ticket_saved(sender, instance, **kwargs):
    realtime.notify_support_update(instance)


@receiver(post_save, sender="recycling.MarketplaceListing")
def listing_created(sender, instance, created, **kwargs):
    if created and instance.status == "AVAILABLE":
        realtime.notify_recycling_offer(instance)


@receiver(post_save, sender="core.Zone")
def zone_saved(sender, instance, **kwargs):
    realtime.notify_zone_update(instance)


@receiver(post_save, sender="tracking.LiveLocation")
def live_location_saved(sender, instance, **kwargs):
    try:
        realtime.notify_collector_location(instance)
    except Exception:
        logger.exception("Failed to push collector location update")
