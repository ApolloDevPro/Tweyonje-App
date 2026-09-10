"""
Supabase Database Utilities for Django

This module provides utility functions for working with Supabase PostgreSQL
database from Django views and models.
"""

import uuid
from datetime import datetime
from django.conf import settings
from django.db import connection


class SupabaseDB:
    """Utility class for Supabase database operations."""
    
    @staticmethod
    def generate_uuid():
        """Generate a new UUID."""
        return str(uuid.uuid4())
    
    @staticmethod
    def generate_reference_id(prefix):
        """Generate a unique reference ID."""
        timestamp = datetime.now().strftime('%Y%m%d')
        random_part = uuid.uuid4().hex[:6].upper()
        return f"{prefix}-{timestamp}-{random_part}"
    
    @staticmethod
    def execute_query(query, params=None):
        """Execute a raw SQL query and return results."""
        with connection.cursor() as cursor:
            cursor.execute(query, params)
            columns = [col[0] for col in cursor.description]
            return [dict(zip(columns, row)) for row in cursor.fetchall()]
    
    @staticmethod
    def execute_insert(query, params=None):
        """Execute an insert query and return the inserted row."""
        with connection.cursor() as cursor:
            cursor.execute(query, params)
            if cursor.description:
                columns = [col[0] for col in cursor.description]
                return dict(zip(columns, cursor.fetchone()))
            return None
    
    @staticmethod
    def get_user_by_supabase_id(supabase_id):
        """Get a user profile by Supabase user ID."""
        query = """
            SELECT * FROM profiles WHERE id = %s
        """
        results = SupabaseDB.execute_query(query, [supabase_id])
        return results[0] if results else None
    
    @staticmethod
    def get_waste_requests(user_id=None, status=None, limit=50, offset=0):
        """Get waste requests with optional filters."""
        query = """
            SELECT 
                wr.*,
                wc.name as category_name,
                wc.slug as category_slug,
                p.full_name as collector_name
            FROM waste_requests wr
            LEFT JOIN waste_categories wc ON wr.category_id = wc.id
            LEFT JOIN profiles p ON wr.assigned_collector_id = p.id
            WHERE 1=1
        """
        params = []
        
        if user_id:
            query += " AND wr.user_id = %s"
            params.append(user_id)
        
        if status:
            query += " AND wr.status = %s"
            params.append(status)
        
        query += " ORDER BY wr.created_at DESC LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        return SupabaseDB.execute_query(query, params)
    
    @staticmethod
    def get_waste_request_by_id(request_id, user_id=None):
        """Get a single waste request by ID."""
        query = """
            SELECT 
                wr.*,
                wc.name as category_name,
                wc.slug as category_slug,
                wc.default_price_per_kg,
                p.full_name as collector_name,
                p.phone as collector_phone
            FROM waste_requests wr
            LEFT JOIN waste_categories wc ON wr.category_id = wc.id
            LEFT JOIN profiles p ON wr.assigned_collector_id = p.id
            WHERE wr.id = %s
        """
        params = [request_id]
        
        if user_id:
            query += " AND wr.user_id = %s"
            params.append(user_id)
        
        results = SupabaseDB.execute_query(query, params)
        return results[0] if results else None
    
    @staticmethod
    def create_waste_request(user_id, category_id, pickup_address, estimated_weight_kg, **kwargs):
        """Create a new waste request."""
        reference_id = SupabaseDB.generate_reference_id('WR')
        
        query = """
            INSERT INTO waste_requests (
                reference_id, user_id, category_id, pickup_address,
                latitude, longitude, estimated_weight_kg, scheduled_date,
                scheduled_time_slot, special_instructions, estimated_price, zone_id
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
            RETURNING *
        """
        
        params = [
            reference_id,
            user_id,
            category_id,
            pickup_address,
            kwargs.get('latitude'),
            kwargs.get('longitude'),
            estimated_weight_kg,
            kwargs.get('scheduled_date'),
            kwargs.get('scheduled_time_slot'),
            kwargs.get('special_instructions'),
            kwargs.get('estimated_price', 0),
            kwargs.get('zone_id'),
        ]
        
        return SupabaseDB.execute_insert(query, params)
    
    @staticmethod
    def update_waste_request_status(request_id, status, user_id=None):
        """Update waste request status."""
        query = """
            UPDATE waste_requests
            SET status = %s, updated_at = NOW()
            WHERE id = %s
        """
        params = [status, request_id]
        
        if user_id:
            query += " AND user_id = %s"
            params.append(user_id)
        
        query += " RETURNING *"
        
        return SupabaseDB.execute_insert(query, params)
    
    @staticmethod
    def assign_collector(request_id, collector_id):
        """Assign a collector to a waste request."""
        reference_id = SupabaseDB.generate_reference_id('ASN')
        
        query = """
            INSERT INTO collection_assignments (
                reference_id, waste_request_id, collector_id, status
            ) VALUES (
                %s, %s, %s, 'ASSIGNED'
            )
            RETURNING *
        """
        
        # Also update the waste request
        update_query = """
            UPDATE waste_requests
            SET assigned_collector_id = %s, status = 'ASSIGNED', updated_at = NOW()
            WHERE id = %s
            RETURNING *
        """
        
        assignment = SupabaseDB.execute_insert(query, [reference_id, request_id, collector_id])
        SupabaseDB.execute_insert(update_query, [collector_id, request_id])
        
        return assignment
    
    @staticmethod
    def get_zone_by_location(latitude, longitude):
        """Find zone based on location (simplified - would need PostGIS for accurate results)."""
        query = """
            SELECT * FROM zones
            WHERE is_active = true
            ORDER BY name
            LIMIT 1
        """
        results = SupabaseDB.execute_query(query)
        return results[0] if results else None
    
    @staticmethod
    def get_waste_categories(is_active=True):
        """Get all active waste categories."""
        query = """
            SELECT * FROM waste_categories
            WHERE is_active = %s
            ORDER BY name
        """
        return SupabaseDB.execute_query(query, [is_active])
    
    @staticmethod
    def get_user_reward_wallet(user_id):
        """Get user's reward wallet."""
        query = """
            SELECT * FROM reward_wallets
            WHERE user_id = %s
        """
        results = SupabaseDB.execute_query(query, [user_id])
        return results[0] if results else None
    
    @staticmethod
    def award_eco_points(user_id, points):
        """Award eco points to user."""
        query = """
            INSERT INTO reward_wallets (user_id, balance, total_earned, tier)
            VALUES (%s, %s, %s, 'BRONZE')
            ON CONFLICT (user_id) DO UPDATE
            SET 
                balance = reward_wallets.balance + %s,
                total_earned = reward_wallets.total_earned + %s,
                updated_at = NOW()
            RETURNING *
        """
        return SupabaseDB.execute_insert(query, [user_id, points, points, points, points])
    
    @staticmethod
    def get_payment_history(user_id, limit=50, offset=0):
        """Get payment history for a user."""
        query = """
            SELECT 
                p.*,
                wr.reference_id as waste_request_reference
            FROM payments p
            LEFT JOIN waste_requests wr ON p.waste_request_id = wr.id
            WHERE p.user_id = %s
            ORDER BY p.created_at DESC
            LIMIT %s OFFSET %s
        """
        return SupabaseDB.execute_query(query, [user_id, limit, offset])
    
    @staticmethod
    def create_payment(user_id, amount, method, phone_number=None, waste_request_id=None):
        """Create a new payment."""
        reference_id = SupabaseDB.generate_reference_id('PAY')
        
        query = """
            INSERT INTO payments (
                reference_id, user_id, waste_request_id, amount, currency,
                method, phone_number, status
            ) VALUES (
                %s, %s, %s, %s, 'UGX', %s, %s, 'PENDING'
            )
            RETURNING *
        """
        
        return SupabaseDB.execute_insert(query, [
            reference_id, user_id, waste_request_id, amount, method, phone_number
        ])
    
    @staticmethod
    def update_payment_status(payment_id, status, transaction_id=None):
        """Update payment status."""
        query = """
            UPDATE payments
            SET status = %s, transaction_id = %s, updated_at = NOW()
            WHERE id = %s
            RETURNING *
        """
        return SupabaseDB.execute_insert(query, [status, transaction_id, payment_id])
    
    @staticmethod
    def get_notifications(user_id, unread_only=False, limit=50):
        """Get notifications for a user."""
        query = """
            SELECT * FROM notifications
            WHERE user_id = %s
        """
        params = [user_id]
        
        if unread_only:
            query += " AND is_read = false"
        
        query += " ORDER BY created_at DESC LIMIT %s"
        params.append(limit)
        
        return SupabaseDB.execute_query(query, params)
    
    @staticmethod
    def mark_notification_read(notification_id, user_id):
        """Mark a notification as read."""
        query = """
            UPDATE notifications
            SET is_read = true
            WHERE id = %s AND user_id = %s
            RETURNING *
        """
        return SupabaseDB.execute_insert(query, [notification_id, user_id])
    
    @staticmethod
    def get_support_tickets(user_id=None, status=None, limit=50):
        """Get support tickets."""
        query = """
            SELECT * FROM support_tickets
            WHERE 1=1
        """
        params = []
        
        if user_id:
            query += " AND user_id = %s"
            params.append(user_id)
        
        if status:
            query += " AND status = %s"
            params.append(status)
        
        query += " ORDER BY created_at DESC LIMIT %s"
        params.append(limit)
        
        return SupabaseDB.execute_query(query, params)
    
    @staticmethod
    def create_support_ticket(user_id, subject, category='OTHER', priority='MEDIUM'):
        """Create a new support ticket."""
        ticket_number = SupabaseDB.generate_reference_id('TKT')
        
        query = """
            INSERT INTO support_tickets (
                ticket_number, user_id, subject, category, priority, status
            ) VALUES (
                %s, %s, %s, %s, %s, 'OPEN'
            )
            RETURNING *
        """
        
        return SupabaseDB.execute_insert(query, [
            ticket_number, user_id, subject, category, priority
        ])
