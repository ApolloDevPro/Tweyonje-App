"""Time-series analytics endpoints for trend analysis."""
from datetime import timedelta
from django.db.models import Count, Sum, Avg, F
from django.db.models.functions import TruncDate, TruncWeek, TruncMonth
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Role
from apps.waste_requests.models import WasteRequest
from apps.collections.models import CollectionAssignment
from apps.payments.models import Payment


class CollectionsTrendView(APIView):
    """Daily/weekly/monthly collection trends."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        period = request.query_params.get('period', 'daily')  # daily, weekly, monthly
        days_back = int(request.query_params.get('days', 30))
        
        start_date = timezone.now() - timedelta(days=days_back)
        
        # Determine truncation function
        if period == 'weekly':
            trunc_func = TruncWeek
        elif period == 'monthly':
            trunc_func = TruncMonth
        else:
            trunc_func = TruncDate
        
        # Query collections by period
        data = WasteRequest.objects.filter(
            created_at__gte=start_date,
            status=WasteRequest.Status.COLLECTED
        ).annotate(
            period=trunc_func('created_at')
        ).values('period').annotate(
            count=Count('id'),
            total_weight=Sum('actual_weight_kg'),
            avg_weight=Avg('actual_weight_kg')
        ).order_by('period')
        
        # Calculate moving average (7-period)
        results = list(data)
        if len(results) >= 7:
            for i in range(6, len(results)):
                window = results[i-6:i+1]
                moving_avg = sum(r['count'] for r in window) / 7
                results[i]['moving_avg'] = round(moving_avg, 2)
        
        return Response({
            "period": period,
            "days_back": days_back,
            "data": results,
            "total_collections": sum(r['count'] for r in results),
            "total_weight_kg": sum(float(r['total_weight'] or 0) for r in results),
        })


class CollectorPerformanceTrendView(APIView):
    """Collector performance over time."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        collector_id = request.query_params.get('collector_id')
        days_back = int(request.query_params.get('days', 30))
        
        if not collector_id:
            return Response({"error": "collector_id required"}, status=status.HTTP_400_BAD_REQUEST)
        
        start_date = timezone.now() - timedelta(days=days_back)
        
        # Daily performance
        data = CollectionAssignment.objects.filter(
            collector_id=collector_id,
            assigned_at__gte=start_date,
            status=CollectionAssignment.Status.COLLECTED
        ).annotate(
            date=TruncDate('assigned_at')
        ).values('date').annotate(
            collections_count=Count('id'),
            total_weight=Sum('collected_weight_kg'),
            avg_completion_time=Avg(
                F('updated_at') - F('assigned_at')
            )
        ).order_by('date')
        
        # Calculate efficiency score (collections per hour)
        results = []
        for entry in data:
            avg_time_seconds = entry['avg_completion_time'].total_seconds() if entry['avg_completion_time'] else 0
            avg_time_hours = avg_time_seconds / 3600 if avg_time_seconds > 0 else 1
            efficiency = entry['collections_count'] / avg_time_hours if avg_time_hours > 0 else 0
            
            results.append({
                'date': entry['date'],
                'collections_count': entry['collections_count'],
                'total_weight_kg': float(entry['total_weight'] or 0),
                'avg_completion_hours': round(avg_time_hours, 2),
                'efficiency_score': round(efficiency, 2)
            })
        
        return Response({
            "collector_id": collector_id,
            "days_back": days_back,
            "data": results,
            "total_collections": sum(r['collections_count'] for r in results),
        })


class PaymentSuccessRateTrendView(APIView):
    """Payment success rate trends over time."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        days_back = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days_back)
        
        # Daily payment stats
        data = Payment.objects.filter(
            created_at__gte=start_date
        ).annotate(
            date=TruncDate('created_at')
        ).values('date').annotate(
            total=Count('id'),
            successful=Count('id', filter=models.Q(status=Payment.Status.SUCCESSFUL)),
            failed=Count('id', filter=models.Q(status=Payment.Status.FAILED)),
            pending=Count('id', filter=models.Q(status=Payment.Status.PENDING)),
            total_amount=Sum('amount', filter=models.Q(status=Payment.Status.SUCCESSFUL))
        ).order_by('date')
        
        results = []
        for entry in data:
            success_rate = (entry['successful'] / entry['total'] * 100) if entry['total'] > 0 else 0
            results.append({
                'date': entry['date'],
                'total_transactions': entry['total'],
                'successful': entry['successful'],
                'failed': entry['failed'],
                'pending': entry['pending'],
                'success_rate': round(success_rate, 1),
                'total_amount_ugx': float(entry['total_amount'] or 0)
            })
        
        # Calculate overall metrics
        overall_total = sum(r['total_transactions'] for r in results)
        overall_success = sum(r['successful'] for r in results)
        overall_rate = (overall_success / overall_total * 100) if overall_total > 0 else 0
        
        return Response({
            "days_back": days_back,
            "data": results,
            "overall": {
                "total_transactions": overall_total,
                "successful": overall_success,
                "success_rate": round(overall_rate, 1),
                "total_revenue_ugx": sum(r['total_amount_ugx'] for r in results)
            }
        })


class UserGrowthTrendView(APIView):
    """User registration and growth trends."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        from django.contrib.auth import get_user_model
        
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        User = get_user_model()
        days_back = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days_back)
        
        # Daily new users by role
        data = User.objects.filter(
            created_at__gte=start_date
        ).annotate(
            date=TruncDate('created_at')
        ).values('date').annotate(
            total_new=Count('id'),
            residents=Count('id', filter=models.Q(role=Role.RESIDENT)),
            collectors=Count('id', filter=models.Q(role=Role.COLLECTOR)),
            recyclers=Count('id', filter=models.Q(role=Role.RECYCLER)),
        ).order_by('date')
        
        # Calculate cumulative totals
        results = []
        cumulative = 0
        for entry in data:
            cumulative += entry['total_new']
            results.append({
                'date': entry['date'],
                'new_users': entry['total_new'],
                'cumulative_users': cumulative,
                'residents': entry['residents'],
                'collectors': entry['collectors'],
                'recyclers': entry['recyclers'],
            })
        
        return Response({
            "days_back": days_back,
            "data": results,
            "total_new_users": sum(r['new_users'] for r in results),
        })


class WasteCategoryTrendView(APIView):
    """Waste category distribution over time."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role not in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        days_back = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days_back)
        
        from apps.waste_requests.models import WasteCategory
        
        categories = WasteCategory.objects.all()
        category_data = {}
        
        for category in categories:
            weekly_data = WasteRequest.objects.filter(
                category=category,
                created_at__gte=start_date,
                status=WasteRequest.Status.COLLECTED
            ).annotate(
                week=TruncWeek('created_at')
            ).values('week').annotate(
                count=Count('id'),
                total_weight=Sum('actual_weight_kg')
            ).order_by('week')
            
            category_data[category.name] = list(weekly_data)
        
        return Response({
            "days_back": days_back,
            "categories": category_data
        })


# Import models at the end to avoid circular imports
from django.db import models
