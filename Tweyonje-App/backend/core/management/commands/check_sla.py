"""
check_sla: Escalate support tickets that have passed their SLA deadline.

This command:
1. Finds tickets past SLA deadline
2. Marks them as escalated
3. Sends notifications to admins/authorities
4. Logs escalation events
"""
import logging
from django.core.management.base import BaseCommand

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Escalate support tickets past their SLA deadline"

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Preview escalations without committing them',
        )
        parser.add_argument(
            '--notify',
            action='store_true',
            default=True,
            help='Send notifications to admins (default: True)',
        )

    def handle(self, *args, **options):
        from django.utils import timezone
        from django.contrib.auth import get_user_model
        from apps.support.models import SupportTicket
        from apps.support.services import escalate_ticket
        from apps.notifications.services import send_notification
        from apps.notifications.models import Notification
        from core.models import Role
        
        User = get_user_model()
        dry_run = options['dry_run']
        send_notifications = options['notify']
        now = timezone.now()
        
        # Find overdue tickets
        overdue = SupportTicket.objects.filter(
            status__in=[SupportTicket.Status.OPEN, SupportTicket.Status.IN_PROGRESS],
            sla_deadline__lt=now,
            is_escalated=False,
        ).select_related('user')
        
        count = overdue.count()
        
        if count == 0:
            self.stdout.write(self.style.SUCCESS("No overdue tickets found."))
            return
        
        self.stdout.write(self.style.NOTICE(
            f"Found {count} ticket(s) past SLA deadline"
        ))
        
        if dry_run:
            for ticket in overdue:
                hours_overdue = (now - ticket.sla_deadline).total_seconds() / 3600
                self.stdout.write(
                    f"  [DRY RUN] Would escalate: {ticket.ticket_number} "
                    f"({hours_overdue:.1f}h overdue) - {ticket.subject}"
                )
            return
        
        # Get admin users for notifications
        admin_users = User.objects.filter(
            role__in=[Role.ADMINISTRATOR, Role.AUTHORITY]
        )
        
        escalated_tickets = []
        
        for ticket in overdue:
            hours_overdue = (now - ticket.sla_deadline).total_seconds() / 3600
            
            # Escalate ticket (increases priority, assigns if needed)
            escalate_ticket(ticket)
            
            escalated_tickets.append({
                'ticket': ticket,
                'hours_overdue': hours_overdue
            })
            
            self.stdout.write(
                self.style.WARNING(
                    f"  ⚠ Escalated: {ticket.ticket_number} to {ticket.priority} priority "
                    f"({hours_overdue:.1f}h overdue)"
                )
            )
            
            # Send notification to ticket creator
            if send_notifications:
                try:
                    send_notification(
                        recipient=ticket.user,
                        title="Support Ticket Escalated",
                        message=(
                            f"Your support ticket #{ticket.ticket_number} has been escalated "
                            f"due to extended response time. Our team will prioritize your issue."
                        ),
                        channel=Notification.Channel.IN_APP,
                        metadata={
                            'ticket_id': str(ticket.id),
                            'ticket_number': ticket.ticket_number,
                            'type': 'ticket_escalated',
                        }
                    )
                except Exception as e:
                    logger.error(f"Failed to notify ticket creator: {e}")
        
        # Send summary notification to admins
        if send_notifications and admin_users.exists():
            summary_message = (
                f"{count} support ticket(s) have been escalated due to SLA breach:\n\n"
            )
            for item in escalated_tickets[:10]:  # Max 10 in summary
                ticket = item['ticket']
                summary_message += (
                    f"• #{ticket.ticket_number}: {ticket.subject} "
                    f"({item['hours_overdue']:.1f}h overdue)\n"
                )
            
            if count > 10:
                summary_message += f"\n...and {count - 10} more"
            
            for admin in admin_users:
                try:
                    send_notification(
                        recipient=admin,
                        title=f"⚠️ {count} Ticket(s) Escalated - SLA Breach",
                        message=summary_message,
                        channel=Notification.Channel.IN_APP,
                        metadata={
                            'type': 'sla_breach_summary',
                            'count': count,
                        }
                    )
                except Exception as e:
                    logger.error(f"Failed to notify admin {admin.email}: {e}")
        
        summary = (
            f"\nSLA check complete:\n"
            f"  • {count} ticket(s) escalated\n"
            f"  • {admin_users.count()} admin(s) notified"
        )
        self.stdout.write(self.style.SUCCESS(summary))
