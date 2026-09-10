"""
process_due_schedules: Create waste requests from recurring schedules due today.
"""
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Generate waste requests from recurring schedules that are due today"

    def handle(self, *args, **kwargs):
        from datetime import date
        from django.utils import timezone
        from apps.waste_requests.models import RecurringSchedule, WasteRequest

        today = timezone.now().date()
        weekday = today.weekday()

        schedules = RecurringSchedule.objects.filter(is_active=True, preferred_weekday=weekday)
        created = 0

        for schedule in schedules:
            existing = WasteRequest.objects.filter(
                schedule=schedule,
                created_at__date=today,
            ).exists()

            if not existing:
                WasteRequest.objects.create(
                    user=schedule.user,
                    category=schedule.category,
                    schedule=schedule,
                    estimated_weight_kg=5.0,
                    pickup_address=schedule.address,
                    latitude=schedule.latitude,
                    longitude=schedule.longitude,
                    zone=schedule.zone,
                    scheduled_date=today,
                    scheduled_time_slot=str(schedule.preferred_time) if schedule.preferred_time else "",
                    status=WasteRequest.Status.PENDING,
                )
                schedule.last_generated_at = timezone.now()
                schedule.save(update_fields=["last_generated_at"])
                created += 1

        self.stdout.write(self.style.SUCCESS(f"Created {created} waste requests from {schedules.count()} due schedules."))
