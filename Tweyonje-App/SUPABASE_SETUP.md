# Supabase Setup Guide for Tweyonje

## Step 1: Run Schema Migration

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: `knskyxabdwxutyriravt`
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
6. Click **Run** button (or press Ctrl+Enter)

**Expected result**: "Success. No rows returned"

## Step 2: Run Seed Data

1. In SQL Editor, click **New Query** again
2. Copy the contents of `supabase/migrations/002_seed_data.sql`
3. Click **Run**

**Expected result**: "Success. No rows returned"

## Step 3: Verify Setup

### Option A: From Supabase Dashboard
1. Go to **Table Editor** (left sidebar)
2. You should see all 20+ tables listed
3. Click on `zones` - should see 7 zones (Kampala areas)
4. Click on `waste_categories` - should see 10 categories
5. Click on `reward_tiers` - should see 4 tiers

### Option B: From Flutter App
1. Run your app: `flutter run`
2. Navigate to: `/supabase-test`
3. The test screen will show:
   - Connection status
   - Schema verification (which tables exist)
   - Seed data verification

## Step 4: Create Test User (Optional)

To create a test user in Supabase:

1. Go to **Authentication** > **Users**
2. Click **Add User**
3. Enter:
   - Email: `test@tweyonje.ug`
   - Password: `Test123456!`
4. Click **Create User**

Then create a profile for this user:

1. Go to **SQL Editor**
2. Run this query (replace the UUID with the user's ID from step 4):

```sql
INSERT INTO profiles (id, email, full_name, first_name, last_name, phone, role)
VALUES (
  'USER_UUID_HERE',
  'test@tweyonje.ug',
  'Test User',
  'Test',
  'User',
  '+256700000000',
  'RESIDENT'
);
```

## Troubleshooting

### "relation does not exist" error
- The schema migration hasn't been run yet
- Go back to Step 1

### "permission denied" error
- RLS policies are blocking access
- Check the policies in Table Editor > [table] > Policies

### "column does not exist" error
- Schema might be outdated
- Re-run the migration (it uses IF NOT EXISTS, so safe to run)

### Connection test shows "tables_not_found"
- Tables haven't been created yet
- Run the schema migration

## Tables Reference

| Table | Description |
|-------|-------------|
| zones | Waste collection zones (7 Kampala areas) |
| profiles | User profiles (extends auth.users) |
| waste_categories | Types of waste (10 categories) |
| waste_requests | Main pickup requests |
| waste_request_photos | Photos for requests |
| recurring_schedules | Scheduled pickups |
| collection_shifts | Collector work shifts |
| collection_assignments | Job assignments |
| live_locations | Real-time tracking |
| payments | Payment records |
| invoices | Generated invoices |
| reward_wallets | User reward balances |
| reward_tiers | Loyalty tiers (Bronze-Platinum) |
| reward_redemptions | Reward redemptions |
| rating_reviews | User ratings |
| notifications | User notifications |
| notification_preferences | Notification settings |
| chat_conversations | Chat threads |
| chat_messages | Chat messages |
| support_tickets | Support system |
| ticket_messages | Ticket messages |
| illegal_dumping_reports | Incident reports |
| report_photos | Report photos |
| recycling_offers | Recycling marketplace |
| recycling_transactions | Recycling purchases |
| collection_routes | Optimized routes |
| admin_settings | System config (10 settings) |
| audit_logs | Activity logs |
| fcm_devices | Push notification tokens |
