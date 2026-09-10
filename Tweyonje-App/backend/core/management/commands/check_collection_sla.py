"""
check_collection_sla: Monitor waste collection assignments for SLA breaches.

This command checks:
1. Assignments not started within X hours of scheduled time
2. Collections taking too long to complete
3. Sends notifications to collectors and admins
"""
import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Monitor waste collection assignments for SLA breaches"

    def add_arguments(self, parser):
        parser.add_argument(
            '--start-delay-hours',
            type=int,
            default=2,
            help='Hours after scheduled time before flagging late start (default: 2)',
        )
        parser.add_argument(
            '--completion-delay-hours',
            type=int,
            default=4,
            help='Hours after arrival before flagging slow completion (default: 4)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Preview violations without taking action',
        )

    def handle(self, *args, **options):
        from apps.collections.models import CollectionAssignment
        from apps.notifications.services import send_notification
        from apps.notifications.models import Notification
        
        dry_run = options['dry_run']
        start_delay = timedelta(hours=options['start_delay_hours'])
        completion_delay = timedelta(hours=options['completion_delay_hours'])
        now = timezone.now()
        
        # Check 1: Assigned but not started
        late_starts = CollectionAssignment.objects.filter(
            status=CollectionAssignment.Status.ASSIGNED,
            assigned_at__lt=now - start_delay,
        ).select_related('collector', 'waste_request', 'vehicle')
        
        # Check 2: Arrived but not completed
        slow_completions = CollectionAssignment.objects.filter(
            status=CollectionAssignment.Status.ARRIVED,
        ).select_related('collector', 'waste_request')
        
        # Filter slow completions based on time at arrival
        slow_list = []
        for assignment in slow_completions:
            # Check time since status changed to ARRIVED
            time_at_arrived = assignment.updated_at
            if time_at_arrived < now - completion_delay:
                slow_list.append(assignment)
        
        late_start_count = late_starts.count()
        slow_completion_count = len(slow_list)
        
        self.stdout.write(self.style.NOTICE(
            f"Collection SLA Check:\n"
            f"  • {late_start_count} assignment(s) with delayed start\n"
            f"  • {slow_completion_count} assignment(s) with slow completion"
        ))
        
        if late_start_count == 0 and slow_completion_count == 0:
            self.stdout.write(self.style.SUCCESS("No SLA violations found."))
            return
        
        # Handle late starts
        for assignment in late_starts:
            hours_late = (now - assignment.assigned_at).total_seconds() / 3600
            
            self.stdout.write(
                self.style.WARNING(
                    f"  ⏰ Late start: {assignment.waste_request.reference_id} "
                    f"assigned to {assignment.collector.full_name} "
                    f"({hours_late:.1f}h ago, not started)"
                )
            )
            
            if dry_run:
                continue
            
            # Notify collector
            try:
                send_notification(
                    recipient=assignment.collector,
                    title="⏰ Collection Assignment Overdue",
                    message=(
                        f"Your collection assignment {assignment.waste_request.reference_id} "
                        f"was scheduled {hours_late:.1f} hours ago. "
                        f"Please start the collection or contact support."
                    ),
                    channel=Notification.Channel.PUSH,
                    metadata={
                        'assignment_id': str(assignment.id),
                        'request_id': str(assignment.waste_request_id),
                        'type': 'collection_late_start',
                    }
                )
            except Exception as e:
                logger.error(f"Failed to notify collector: {e}")
            
            # Notify resident
            try:
                send_notification(
                    recipient=assignment.waste_request.user,
                    title="Collection Delayed",
                    message=(
                        f"Your waste collection {assignment.waste_request.reference_id} "
                        f"is experiencing delays. We're working to resolve this."
                    ),
                    channel=Notification.Channel.IN_APP,
                    metadata={
                        'request_id': str(assignment.waste_request_id),
                        'type': 'collection_delayed',
                    }
                )
            except Exception as e:
                logger.error(f"Failed to notify resident: {e}")
        
        # Handle slow completions
        for assignment in slow_list:
            time_at_location = (now - assignment.updated_at).total_seconds() / 3600
            
            self.stdout.write(
                self.style.WARNING(
                    f"  🐌 Slow completion: {assignment.waste_request.reference_id} "
                    f"by {assignment.collector.full_name} "
                    f"(at location for {time_at_location:.1f}h)"
                )
            )
            
            if dry_run:
                continue
            
            # Notify collector
            try:
                send_notification(
                    recipient=assignment.collector,
                    title="⚠️ Collection Taking Too Long",
                    message=(
                        f"You've been at the collection location for {time_at_location:.1f} hours. "
                        f"Please complete the collection or report any issues."
                    ),
                    channel=Notification.Channel.PUSH,
                    metadata={
                        'assignment_id': str(assignment.id),
                        'type': 'collection_slow_completion',
                    }
                )
            except Exception as e:
                logger.error(f"Failed to notify collector: {e}")
        
        if not dry_run:
            summary = (
                f"\nCollection SLA enforcement complete:\n"
                f"  • {late_start_count} late start notification(s) sent\n"
                f"  • {slow_completion_count} slow completion notification(s) sent"
            )
            self.stdout.write(self.style.SUCCESS(summary))
        else:
            self.stdout.write("\n[DRY RUN] No actions taken.")
