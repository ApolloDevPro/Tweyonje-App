"""GDPR data export functionality."""
import json
import os
import zipfile
from io import BytesIO
from django.http import FileResponse
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView


class DataExportView(APIView):
    """
    Export all user data for GDPR compliance (Article 20 - Right to Data Portability).
    
    Returns a ZIP file containing:
    - user_profile.json
    - waste_requests.json
    - payments.json
    - chat_messages.json
    - support_tickets.json
    - ratings.json
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        
        # Prepare data export
        export_data = {
            'export_date': timezone.now().isoformat(),
            'user_id': str(user.id),
            'user': self._export_user_profile(user),
            'waste_requests': self._export_waste_requests(user),
            'payments': self._export_payments(user),
            'chat_messages': self._export_chat_messages(user),
            'support_tickets': self._export_support_tickets(user),
            'ratings': self._export_ratings(user),
            'notifications': self._export_notifications(user),
        }
        
        # Create ZIP file in memory
        zip_buffer = BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            # Add each data category as separate JSON file
            for key, data in export_data.items():
                if key not in ['export_date', 'user_id']:
                    json_data = json.dumps(data, indent=2, default=str)
                    zip_file.writestr(f'{key}.json', json_data)
            
            # Add summary file
            summary = {
                'export_date': export_data['export_date'],
                'user_id': export_data['user_id'],
                'user_email': user.email,
                'record_counts': {
                    'waste_requests': len(export_data['waste_requests']),
                    'payments': len(export_data['payments']),
                    'chat_messages': len(export_data['chat_messages']),
                    'support_tickets': len(export_data['support_tickets']),
                    'ratings': len(export_data['ratings']),
                }
            }
            zip_file.writestr('README.json', json.dumps(summary, indent=2))
        
        # Prepare response
        zip_buffer.seek(0)
        filename = f"tweyonje_data_export_{user.id}_{timezone.now().strftime('%Y%m%d')}.zip"
        
        return FileResponse(
            zip_buffer,
            as_attachment=True,
            filename=filename,
            content_type='application/zip'
        )
    
    def _export_user_profile(self, user):
        """Export user profile data."""
        from apps.profiles.models import Profile
        
        data = {
            'id': str(user.id),
            'email': user.email,
            'full_name': user.full_name,
            'phone': user.phone,
            'role': user.role,
            'phone_verified': user.phone_verified,
            'email_verified': user.email_verified,
            'preferred_language': user.preferred_language,
            'created_at': user.created_at.isoformat(),
        }
        
        # Add profile if exists
        if hasattr(user, 'profile'):
            profile = user.profile
            data['profile'] = {
                'bio': profile.bio,
                'address': profile.address,
                'city': profile.city,
                'zone': str(profile.zone_id) if profile.zone else None,
            }
        
        return data
    
    def _export_waste_requests(self, user):
        """Export all waste collection requests."""
        from apps.waste_requests.models import WasteRequest
        
        requests = WasteRequest.objects.filter(user=user).order_by('-created_at')
        
        return [{
            'id': str(req.id),
            'reference_id': req.reference_id,
            'category': req.category.name if req.category else None,
            'pickup_address': req.pickup_address,
            'latitude': float(req.latitude) if req.latitude else None,
            'longitude': float(req.longitude) if req.longitude else None,
            'status': req.status,
            'estimated_weight_kg': float(req.estimated_weight_kg) if req.estimated_weight_kg else None,
            'actual_weight_kg': float(req.actual_weight_kg) if req.actual_weight_kg else None,
            'estimated_price': float(req.estimated_price),
            'payment_status': req.payment_status,
            'is_emergency': req.is_emergency,
            'scheduled_date': req.scheduled_date.isoformat() if req.scheduled_date else None,
            'created_at': req.created_at.isoformat(),
        } for req in requests]
    
    def _export_payments(self, user):
        """Export payment history."""
        from apps.payments.models import Payment
        
        payments = Payment.objects.filter(user=user).order_by('-created_at')
        
        return [{
            'id': str(payment.id),
            'reference_id': payment.reference_id,
            'amount': float(payment.amount),
            'currency': payment.currency,
            'method': payment.method,
            'status': payment.status,
            'transaction_id': payment.transaction_id,
            'created_at': payment.created_at.isoformat(),
        } for payment in payments]
    
    def _export_chat_messages(self, user):
        """Export chat message history."""
        from apps.chat.models import ChatMessage
        
        messages = ChatMessage.objects.filter(sender=user).order_by('-created_at')
        
        return [{
            'id': str(msg.id),
            'conversation_id': str(msg.conversation_id),
            'content': msg.content,
            'is_read': msg.is_read,
            'created_at': msg.created_at.isoformat(),
        } for msg in messages]
    
    def _export_support_tickets(self, user):
        """Export support ticket history."""
        from apps.support.models import SupportTicket
        
        tickets = SupportTicket.objects.filter(user=user).order_by('-created_at')
        
        return [{
            'id': str(ticket.id),
            'ticket_number': ticket.ticket_number,
            'subject': ticket.subject,
            'category': ticket.category,
            'priority': ticket.priority,
            'status': ticket.status,
            'created_at': ticket.created_at.isoformat(),
        } for ticket in tickets]
    
    def _export_ratings(self, user):
        """Export ratings given and received."""
        from apps.ratings.models import Rating
        
        given = Rating.objects.filter(from_user=user)
        received = Rating.objects.filter(to_user=user)
        
        return {
            'given': [{
                'id': str(rating.id),
                'to_user_email': rating.to_user.email if rating.to_user else None,
                'rating': rating.rating,
                'comment': rating.comment,
                'created_at': rating.created_at.isoformat(),
            } for rating in given],
            'received': [{
                'id': str(rating.id),
                'from_user_email': rating.from_user.email,
                'rating': rating.rating,
                'comment': rating.comment,
                'created_at': rating.created_at.isoformat(),
            } for rating in received]
        }
    
    def _export_notifications(self, user):
        """Export notification history."""
        from apps.notifications.models import Notification
        
        notifications = Notification.objects.filter(recipient=user).order_by('-created_at')[:100]
        
        return [{
            'id': str(notif.id),
            'title': notif.title,
            'message': notif.message,
            'channel': notif.channel,
            'status': notif.status,
            'is_read': notif.is_read,
            'created_at': notif.created_at.isoformat(),
        } for notif in notifications]


class DataExportRequestView(APIView):
    """
    Request async data export (for large datasets).
    Returns a task ID that can be polled for completion.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        from core.tasks import export_user_data
        
        # Queue Celery task
        task = export_user_data.delay(str(request.user.id))
        
        return Response({
            'task_id': task.id,
            'status': 'pending',
            'message': 'Data export started. You will receive an email when ready.',
        }, status=status.HTTP_202_ACCEPTED)


class DataExportStatusView(APIView):
    """Check status of async data export."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, task_id):
        from celery.result import AsyncResult
        
        task = AsyncResult(task_id)
        
        if task.ready():
            if task.successful():
                result = task.result
                return Response({
                    'status': 'completed',
                    'download_url': result.get('download_url'),
                })
            else:
                return Response({
                    'status': 'failed',
                    'error': str(task.info),
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            return Response({
                'status': 'pending',
                'progress': task.info.get('progress', 0) if isinstance(task.info, dict) else 0,
            })
