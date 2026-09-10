"""Support ticket management services."""
import logging
from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from core.models import Role
from .models import SupportTicket

User = get_user_model()
logger = logging.getLogger(__name__)


def auto_assign_ticket(ticket):
    """
    Automatically assign a ticket to an available admin/authority.
    
    Assignment logic:
    1. Find admins/authorities
    2. Exclude users on leave or inactive
    3. Pick admin with fewest open tickets
    4. Prioritize by ticket priority
    """
    if ticket.assigned_to:
        # Already assigned
        return ticket.assigned_to
    
    # Find eligible assignees
    eligible_users = User.objects.filter(
        role__in=[Role.ADMINISTRATOR, Role.AUTHORITY],
        is_active=True,
    ).annotate(
        open_ticket_count=Count(
            'assigned_tickets',
            filter=Q(assigned_tickets__status__in=[
                SupportTicket.Status.OPEN,
                SupportTicket.Status.IN_PROGRESS
            ])
        )
    ).order_by('open_ticket_count')
    
    if not eligible_users.exists():
        logger.warning("No eligible users found for ticket auto-assignment")
        return None
    
    # Assign to user with least open tickets
    assignee = eligible_users.first()
    ticket.assigned_to = assignee
    ticket.save(update_fields=['assigned_to', 'updated_at'])
    
    logger.info(
        f"Auto-assigned ticket {ticket.ticket_number} to {assignee.email} "
        f"(currently has {assignee.open_ticket_count} open tickets)"
    )
    
    return assignee


def escalate_ticket(ticket):
    """
    Escalate a ticket by:
    1. Increasing priority
    2. Re-assigning if needed
    3. Sending notifications
    """
    from apps.notifications.services import send_notification
    from apps.notifications.models import Notification
    
    # Increase priority
    priority_upgrade = {
        SupportTicket.Priority.LOW: SupportTicket.Priority.MEDIUM,
        SupportTicket.Priority.MEDIUM: SupportTicket.Priority.HIGH,
        SupportTicket.Priority.HIGH: SupportTicket.Priority.URGENT,
        SupportTicket.Priority.URGENT: SupportTicket.Priority.URGENT,  # Already max
    }
    
    old_priority = ticket.priority
    ticket.priority = priority_upgrade.get(ticket.priority, SupportTicket.Priority.URGENT)
    ticket.is_escalated = True
    
    # Auto-assign if not assigned
    if not ticket.assigned_to:
        assignee = auto_assign_ticket(ticket)
        
        if assignee:
            # Notify newly assigned admin
            try:
                send_notification(
                    recipient=assignee,
                    title=f"🚨 Escalated Ticket Assigned: {ticket.ticket_number}",
                    message=(
                        f"An escalated {ticket.priority} priority ticket has been assigned to you:\n"
                        f"Subject: {ticket.subject}\n"
                        f"Category: {ticket.get_category_display()}\n"
                        f"Requires immediate attention."
                    ),
                    channel=Notification.Channel.PUSH,
                    metadata={
                        'ticket_id': str(ticket.id),
                        'ticket_number': ticket.ticket_number,
                        'type': 'ticket_escalated_assigned',
                    }
                )
            except Exception as e:
                logger.error(f"Failed to notify assignee: {e}")
    else:
        # Notify existing assignee of escalation
        try:
            send_notification(
                recipient=ticket.assigned_to,
                title=f"🚨 Ticket Escalated: {ticket.ticket_number}",
                message=(
                    f"Your assigned ticket has been escalated to {ticket.priority} priority:\n"
                    f"Subject: {ticket.subject}\n"
                    f"Requires immediate attention."
                ),
                channel=Notification.Channel.PUSH,
                metadata={
                    'ticket_id': str(ticket.id),
                    'ticket_number': ticket.ticket_number,
                    'type': 'ticket_escalated',
                }
            )
        except Exception as e:
            logger.error(f"Failed to notify assignee: {e}")
    
    ticket.save(update_fields=['priority', 'is_escalated', 'assigned_to', 'updated_at'])
    
    logger.info(
        f"Escalated ticket {ticket.ticket_number} from {old_priority} to {ticket.priority}"
    )
    
    return ticket


def notify_ticket_resolution(ticket):
    """Send notification when ticket is resolved."""
    from apps.notifications.services import send_notification
    from apps.notifications.models import Notification
    
    try:
        send_notification(
            recipient=ticket.user,
            title=f"Ticket Resolved: {ticket.ticket_number}",
            message=(
                f"Your support ticket has been resolved:\n"
                f"Subject: {ticket.subject}\n\n"
                f"If the issue persists, you can reopen this ticket by replying."
            ),
            channel=Notification.Channel.IN_APP,
            metadata={
                'ticket_id': str(ticket.id),
                'ticket_number': ticket.ticket_number,
                'type': 'ticket_resolved',
            }
        )
    except Exception as e:
        logger.error(f"Failed to send resolution notification: {e}")
