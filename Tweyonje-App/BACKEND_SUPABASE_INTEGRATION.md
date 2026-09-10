# Django Backend + Supabase Integration Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
├─────────────────────────────────────────────────────────────┤
│  Auth: Supabase Auth ──────────────────────────────────────►│
│  Storage: Supabase Storage ────────────────────────────────►│
│  Realtime: Supabase Realtime ──────────────────────────────►│
│  Business Logic: Django REST API ◄─────────────────────────►│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Project                          │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL Database ◄─────────────────────────────────────►│
│  Auth Service                                               │
│  Storage Service                                            │
│  Realtime Service                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Django Backend                            │
├─────────────────────────────────────────────────────────────┤
│  REST API (Business Logic)                                  │
│  Direct PostgreSQL Connection to Supabase                   │
│  Background Tasks                                           │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Connect Django to Supabase PostgreSQL

### Install PostgreSQL adapter

```bash
pip install psycopg2-binary
```

### Update Django settings.py

```python
# settings.py

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'postgres',  # Default Supabase database
        'USER': 'postgres',  # Supabase username
        'PASSWORD': 'your-supabase-db-password',  # From Supabase Dashboard > Settings > Database
        'HOST': 'db.knskyxabdwxutyriravt.supabase.co',  # Supabase host
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'require',  # Required for Supabase
        },
    }
}

# Connection pooling (recommended for Supabase)
DATABASES['default']['CONN_MAX_AGE'] = 600
DATABASES['default']['CONN_HEALTH_CHECKS'] = True
```

### Find your database password

1. Go to Supabase Dashboard
2. Click **Settings** (gear icon)
3. Click **Database**
4. Copy the **Connection string** password

## Step 2: Update Django Models

Since tables are already created in Supabase, you need to tell Django about them.

### Option A: Use `managed = False`

```python
# models.py

from django.db import models

class Zone(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, unique=True)
    region = models.CharField(max_length=255, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = False  # Tell Django not to create/modify this table
        db_table = 'zones'

class Profile(models.Model):
    id = models.UUIDField(primary_key=True)  # References auth.users
    email = models.EmailField()
    full_name = models.CharField(max_length=255)
    first_name = models.CharField(max_length=255, null=True, blank=True)
    last_name = models.CharField(max_length=255, null=True, blank=True)
    phone = models.CharField(max_length=50, null=True, blank=True)
    role = models.CharField(max_length=50, default='RESIDENT')
    # ... other fields

    class Meta:
        managed = False
        db_table = 'profiles'

# Repeat for all tables...
```

### Option B: Use `inspectdb`

```bash
# Generate models from existing database
python manage.py inspectdb > models_import.py

# Copy the models you need into your actual models.py
# Add `managed = False` to each model
```

## Step 3: Authenticate Requests via Supabase

### Verify Supabase JWT in Django

```python
# middleware.py

import jwt
from django.conf import settings
from django.http import JsonResponse

class SupabaseAuthMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Skip auth for public endpoints
        if request.path.startswith('/api/auth/'):
            return self.get_response(request)

        # Get Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if not auth_header.startswith('Bearer '):
            return JsonResponse({'error': 'Missing authorization header'}, status=401)

        token = auth_header.split(' ')[1]

        try:
            # Verify Supabase JWT
            payload = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,  # From Supabase Dashboard > Settings > API
                algorithms=['HS256'],
                audience='authenticated',
            )

            # Add user info to request
            request.supabase_user = payload
            request.supabase_user_id = payload.get('sub')

        except jwt.ExpiredSignatureError:
            return JsonResponse({'error': 'Token expired'}, status=401)
        except jwt.InvalidTokenError:
            return JsonResponse({'error': 'Invalid token'}, status=401)

        return self.get_response(request)
```

### Add to settings.py

```python
# settings.py

MIDDLEWARE = [
    # ... other middleware
    'your_app.middleware.SupabaseAuthMiddleware',
]

# Supabase JWT Secret (from Supabase Dashboard > Settings > API > JWT Secret)
SUPABASE_JWT_SECRET = 'your-supabase-jwt-secret'
```

## Step 4: Update Django Views

### Use Supabase user ID instead of Django user

```python
# views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class WasteRequestListView(APIView):
    def get(self, request):
        # Get user ID from Supabase JWT
        user_id = request.supabase_user_id

        # Query using Supabase user ID
        waste_requests = WasteRequest.objects.filter(
            user_id=user_id
        ).select_related('category', 'assigned_collector')

        serializer = WasteRequestSerializer(waste_requests, many=True)
        return Response(serializer.data)

    def post(self, request):
        user_id = request.supabase_user_id

        # Create waste request with Supabase user ID
        waste_request = WasteRequest.objects.create(
            user_id=user_id,
            reference_id=generate_reference_id(),
            **request.data
        )

        serializer = WasteRequestSerializer(waste_request)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
```

## Step 5: Sync User Profiles

### Create profile on Supabase signup (Database Trigger)

```sql
-- Run this in Supabase SQL Editor

-- Function to create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, first_name, last_name, phone, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'RESIDENT')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call function on user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Sync profile updates from Supabase to Django

```sql
-- Function to sync profile updates
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS trigger AS $$
BEGIN
  UPDATE public.profiles
  SET
    email = NEW.email,
    full_name = COALESCE(NEW.raw_user_meta_data->>'full_name', profiles.full_name),
    phone = COALESCE(NEW.raw_user_meta_data->>'phone', profiles.phone),
    updated_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for user updates
CREATE OR REPLACE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_update();
```

## Step 6: Handle Foreign Keys

Since Django models use `managed = False`, you need to handle foreign keys manually.

### Option A: Use raw SQL for complex queries

```python
from django.db import connection

def get_waste_requests_with_details(user_id):
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT wr.*, wc.name as category_name, p.full_name as collector_name
            FROM waste_requests wr
            LEFT JOIN waste_categories wc ON wr.category_id = wc.id
            LEFT JOIN profiles p ON wr.assigned_collector_id = p.id
            WHERE wr.user_id = %s
            ORDER BY wr.created_at DESC
        """, [user_id])
        
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
```

### Option B: Use Django ORM with explicit joins

```python
class WasteRequestQuerySet(models.QuerySet):
    def with_details(self):
        return self.select_related(
            'category',
            'assigned_collector',
            'zone',
        ).prefetch_related('photos')
```

## Step 7: Environment Variables

### Create .env file

```bash
# .env

# Supabase
SUPABASE_URL=https://knskyxabdwxutyriravt.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=your-service-role-key
SUPABASE_JWT_SECRET=your-jwt-secret

# Database (Supabase PostgreSQL)
DB_HOST=db.knskyxabdwxutyriravt.supabase.co
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your-db-password
```

### Update settings.py to use env vars

```python
import os
from dotenv import load_dotenv

load_dotenv()

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'postgres'),
        'USER': os.getenv('DB_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}

SUPABASE_JWT_SECRET = os.getenv('SUPABASE_JWT_SECRET')
```

## Step 8: Test the Connection

### Run Django server

```bash
python manage.py runserver
```

### Test API endpoints

```bash
# Login via Supabase (get JWT)
curl -X POST https://knskyxabdwxutyriravt.supabase.co/auth/v1/token?grant_type=password \
  -H "apikey: your-anon-key" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@tweyonje.ug", "password": "Test123456!"}'

# Use the access_token from response
TOKEN="eyJhbGciOi..."

# Call Django API with Supabase JWT
curl -X GET http://localhost:8000/api/waste-requests/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

## Troubleshooting

### "relation does not exist" error
- Table name might be different (case-sensitive)
- Check table name in Supabase Table Editor

### "permission denied" error
- RLS policies are blocking Django
- Option 1: Add Django service role to RLS policies
- Option 2: Use service_role key for Django (less secure)

### "SSL required" error
- Add `'sslmode': 'require'` to database OPTIONS

### Foreign key errors
- Django models have `managed = False`
- Foreign keys won't be enforced by Django
- Rely on Supabase constraints

## Security Best Practices

1. **Never commit secrets** - Use .env files
2. **Use service_role key only in Django** - Never in Flutter
3. **Validate JWT in Django** - Don't trust client-side auth alone
4. **Enable RLS** - Even with Django, keep RLS enabled
5. **Use connection pooling** - Supabase has connection limits

## Migration Checklist

- [ ] Update Django DATABASES setting
- [ ] Add Supabase JWT middleware
- [ ] Set `managed = False` on all models
- [ ] Create database trigger for user sync
- [ ] Update views to use `request.supabase_user_id`
- [ ] Test API endpoints with Supabase JWT
- [ ] Deploy environment variables
- [ ] Update Flutter app to use Supabase Auth
