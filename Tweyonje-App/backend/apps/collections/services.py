from django.utils import timezone
from datetime import datetime

from apps.waste_requests.models import WasteRequest
from .models import CollectionAssignment, CollectionSlot, CollectorShift


def slot_available(zone, target_date, start_time_obj):
    if not zone or not target_date or not start_time_obj:
        return True

    weekday = target_date.weekday()
    slot = CollectionSlot.objects.filter(
        zone=zone,
        weekday=weekday,
        start_time__lte=start_time_obj,
        end_time__gte=start_time_obj,
        is_active=True,
    ).first()

    if not slot:
        # If no strict slot is configured for the zone, allow request
        return True

    current_count = WasteRequest.objects.filter(
        zone=zone,
        scheduled_date=target_date,
        scheduled_time_slot__icontains=slot.start_time.strftime("%H:%M"),
        status__in=[WasteRequest.Status.PENDING, WasteRequest.Status.SCHEDULED, WasteRequest.Status.ASSIGNED],
    ).count()

    return current_count < slot.max_capacity


def complete_collection(assignment, collected_weight_kg=None, notes=""):
    assignment.status = CollectionAssignment.Status.COLLECTED
    assignment.completed_at = timezone.now()
    if collected_weight_kg:
        assignment.collected_weight_kg = collected_weight_kg
    if notes:
        assignment.notes = notes
    assignment.save()

    # Update associated waste request
    waste_req = assignment.waste_request
    waste_req.status = WasteRequest.Status.COLLECTED
    if collected_weight_kg:
        waste_req.actual_weight_kg = collected_weight_kg
    waste_req.save(update_fields=["status", "actual_weight_kg", "updated_at"])

    # Hook rewards: award eco points idempotently to the resident/user
    from apps.rewards.services import award_eco_points
    base_points = waste_req.category.base_eco_points if waste_req.category else 10
    multiplier = float(waste_req.actual_weight_kg or waste_req.estimated_weight_kg or 1)
    points_to_award = max(int(base_points * multiplier), 5)

    award_eco_points(
        user=waste_req.user,
        points=points_to_award,
        transaction_type="EARNED_COLLECTION",
        source_id=str(waste_req.id),
        description=f"Eco-points for waste collection ({waste_req.reference_id})",
    )

    waste_req.eco_points_awarded = points_to_award
    waste_req.save(update_fields=["eco_points_awarded"])

    return assignment
