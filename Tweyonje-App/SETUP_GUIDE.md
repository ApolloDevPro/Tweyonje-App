# Complete Setup Guide - Run All Migrations

## Step 1: Run SQL Migrations in Supabase

### 1.1 Run Schema Migration

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: `knskyxabdwxutyriravt`
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the contents of `supabase/migrations/001_initial_schema.sql`
6. Click **Run** button (or press Ctrl+Enter)

**Expected result**: "Success. No rows returned"

### 1.2 Run Seed Data Migration

1. Click **New Query** again
2. Copy the contents of `supabase/migrations/002_seed_data.sql`
3. Click **Run**

**Expected result**: "Success. No rows returned"

### 1.3 Run Triggers Migration

1. Click **New Query** again
2. Copy the contents of `supabase/migrations/003_triggers.sql`
3. Click **Run**

**Expected result**: "Success. No rows returned"

## Step 2: Get Supabase Credentials

### 2.1 Get Database Password

1. Go to **Settings** (gear icon in left sidebar)
2. Click **Database**
3. Scroll to **Connection string**
4. Copy the **Password** (or reset if needed)

### 2.2 Get JWT Secret

1. Go to **Settings** > **API**
2. Scroll to **JWT Settings**
3. Copy the **JWT Secret**

### 2.3 Get Service Role Key

1. In **Settings** > **API**
2. Find **Project API keys**
3. Copy the **service_role** key (keep this secret!)

## Step 3: Update Backend .env File

Edit `backend/.env` and fill in:

```bash
# Database - Supabase PostgreSQL
DB_ENGINE=postgres
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your-database-password-from-step-2.1
DB_HOST=db.knskyxabdwxutyriravt.supabase.co
DB_PORT=5432

# Supabase
SUPABASE_URL=https://knskyxabdwxutyriravt.supabase.co
SUPABASE_ANON_KEY=your-anon-key-from-dashboard
SUPABASE_SERVICE_KEY=your-service-role-key-from-step-2.3
SUPABASE_JWT_SECRET=your-jwt-secret-from-step-2.2
```

## Step 4: Test Backend Connection

### 4.1 Install dependencies

```bash
cd backend
pip install -r requirements.txt
pip install psycopg2-binary  # PostgreSQL adapter
```

### 4.2 Test database connection

```bash
python manage.py shell -c "from django.db import connection; cursor = connection.cursor(); cursor.execute('SELECT COUNT(*) FROM zones'); print(f'Zones count: {cursor.fetchone()[0]}')"
```

**Expected output**: `Zones count: 7`

### 4.3 Run Django server

```bash
python manage.py runserver
```

## Step 5: Test Flutter App

### 5.1 Run Flutter app

```bash
cd frontend
flutter run
```

### 5.2 Test Supabase connection

1. Navigate to: `http://localhost:PORT/supabase-test`
2. Check all tabs:
   - **Connection** - Should show "success"
   - **Schema** - Should show all tables exist
   - **Seed Data** - Should show data counts

### 5.3 Create a test user

1. In Supabase Dashboard, go to **Authentication** > **Users**
2. Click **Add User**
3. Enter:
   - Email: `test@tweyonje.ug`
   - Password: `Test123456!`
4. Click **Create User**

### 5.4 Test login in Flutter

1. Go to login screen in Flutter app
2. Enter the test user credentials
3. Should login successfully

## Troubleshooting

### "relation does not exist" error
- Run the schema migration (Step 1.1)
- Check table names are lowercase

### "permission denied" error
- Check RLS policies in Supabase
- Use service_role key for Django (less secure but works)

### "SSL required" error
- Already handled in settings.py (sslmode=require)

### "could not connect to server" error
- Check DB_HOST is correct
- Check if Supabase project is active
- Try disabling SSL: set DB_SSLMODE=disable in .env

### Flutter connection test shows "tables_not_found"
- Tables haven't been created yet
- Run the schema migration

## Quick Test Commands

### Test Supabase REST API (from terminal)

```bash
# List zones
curl "https://knskyxabdwxutyriravt.supabase.co/rest/v1/zones?select=*" \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-anon-key"

# List waste categories
curl "https://knskyxabdwxutyriravt.supabase.co/rest/v1/waste_categories?select=*" \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-anon-key"
```

### Test Django API (from terminal)

```bash
# Login via Supabase to get JWT
curl -X POST "https://knskyxabdwxutyriravt.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: your-anon-key" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@tweyonje.ug", "password": "Test123456!"}'

# Use the access_token from response
TOKEN="eyJhbGciOi..."

# Call Django API
curl "http://localhost:8000/api/waste-requests/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

## Files Created

| File | Purpose |
|------|---------|
| `supabase/migrations/001_initial_schema.sql` | Database schema |
| `supabase/migrations/002_seed_data.sql` | Sample data |
| `supabase/migrations/003_triggers.sql` | Database triggers |
| `backend/core/middleware.py` | JWT authentication |
| `backend/core/supabase_db.py` | Database utilities |
| `backend/.env` | Environment variables |
| `frontend/lib/core/services/supabase_auth_service.dart` | Flutter auth |
| `frontend/lib/core/services/hybrid_file_upload_service.dart` | File uploads |
| `frontend/lib/core/services/hybrid_realtime_service.dart` | Real-time |
| `BACKEND_SUPABASE_INTEGRATION.md` | Integration guide |
