-- ============================================
-- Tweyonje Smart Waste Management - Supabase Schema
-- ============================================

-- Enable PostGIS for location data
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- 1. ZONES
-- ============================================
CREATE TABLE zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  region TEXT,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 2. USERS (extends Supabase auth.users)
-- ============================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'RESIDENT' CHECK (role IN ('RESIDENT', 'BUSINESS', 'COLLECTOR', 'RECYCLER', 'AUTHORITY', 'ADMINISTRATOR')),
  preferred_language TEXT DEFAULT 'en',
  phone_verified BOOLEAN DEFAULT false,
  email_verified BOOLEAN DEFAULT false,
  bio TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  zone_id UUID REFERENCES zones(id),
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 3. WASTE CATEGORIES
-- ============================================
CREATE TABLE waste_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  icon TEXT,
  is_hazardous BOOLEAN DEFAULT false,
  default_price_per_kg DOUBLE PRECISION DEFAULT 0,
  base_eco_points INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 4. WASTE REQUESTS
-- ============================================
CREATE TABLE waste_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES waste_categories(id),
  pickup_address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  estimated_weight_kg DOUBLE PRECISION NOT NULL DEFAULT 0,
  actual_weight_kg DOUBLE PRECISION,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'RESCHEDULED')),
  scheduled_date DATE,
  scheduled_time_slot TEXT,
  special_instructions TEXT,
  estimated_price DOUBLE PRECISION DEFAULT 0,
  paid_amount DOUBLE PRECISION DEFAULT 0,
  payment_status TEXT NOT NULL DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID', 'PARTIAL', 'PAID', 'REFUNDED')),
  eco_points_awarded INTEGER DEFAULT 0,
  assigned_collector_id UUID REFERENCES profiles(id),
  zone_id UUID REFERENCES zones(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 5. WASTE REQUEST PHOTOS
-- ============================================
CREATE TABLE waste_request_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  waste_request_id UUID NOT NULL REFERENCES waste_requests(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  photo_type TEXT DEFAULT 'waste' CHECK (photo_type IN ('waste', 'evidence', 'before', 'after')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 6. RECURRING SCHEDULES
-- ============================================
CREATE TABLE recurring_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES waste_categories(id),
  frequency TEXT NOT NULL DEFAULT 'WEEKLY' CHECK (frequency IN ('DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY')),
  preferred_weekday INTEGER CHECK (preferred_weekday BETWEEN 0 AND 6),
  preferred_time TIME,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  zone_id UUID REFERENCES zones(id),
  is_active BOOLEAN DEFAULT true,
  next_run TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 7. COLLECTIONS / ASSIGNMENTS
-- ============================================
CREATE TABLE collection_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collector_id UUID NOT NULL REFERENCES profiles(id),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE collection_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id TEXT UNIQUE NOT NULL,
  waste_request_id UUID NOT NULL REFERENCES waste_requests(id) ON DELETE CASCADE,
  collector_id UUID NOT NULL REFERENCES profiles(id),
  shift_id UUID REFERENCES collection_shifts(id),
  status TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK (status IN ('ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'COLLECTING', 'COMPLETED', 'FAILED')),
  distance_km DOUBLE PRECISION,
  eta_minutes INTEGER,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 8. LIVE TRACKING
-- ============================================
CREATE TABLE live_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collector_id UUID NOT NULL REFERENCES profiles(id),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  speed DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  accuracy DOUBLE PRECISION,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 9. PAYMENTS
-- ============================================
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id),
  waste_request_id UUID REFERENCES waste_requests(id),
  amount DOUBLE PRECISION NOT NULL,
  currency TEXT NOT NULL DEFAULT 'UGX',
  method TEXT NOT NULL CHECK (method IN ('MTN_MOMO', 'AIRTEL_MONEY', 'CASH', 'CARD', 'BANK_TRANSFER')),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'REFUNDED')),
  phone_number TEXT,
  transaction_id TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE NOT NULL,
  payment_id UUID NOT NULL REFERENCES payments(id),
  user_id UUID NOT NULL REFERENCES profiles(id),
  amount DOUBLE PRECISION NOT NULL,
  currency TEXT NOT NULL DEFAULT 'UGX',
  is_paid BOOLEAN DEFAULT false,
  items JSONB DEFAULT '[]',
  issued_date DATE DEFAULT CURRENT_DATE,
  due_date DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 10. REWARDS
-- ============================================
CREATE TABLE reward_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES profiles(id),
  balance INTEGER NOT NULL DEFAULT 0,
  total_earned INTEGER NOT NULL DEFAULT 0,
  total_redeemed INTEGER NOT NULL DEFAULT 0,
  tier TEXT DEFAULT 'BRONZE' CHECK (tier IN ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM')),
  badge TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE reward_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  min_points INTEGER NOT NULL,
  max_points INTEGER,
  badge TEXT,
  benefits JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE reward_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  points_redeemed INTEGER NOT NULL,
  item_name TEXT NOT NULL,
  item_description TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DISBURSED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 11. RATINGS & REVIEWS
-- ============================================
CREATE TABLE rating_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES profiles(id),
  to_user_id UUID NOT NULL REFERENCES profiles(id),
  waste_request_id UUID REFERENCES waste_requests(id),
  score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  review TEXT,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 12. NOTIFICATIONS
-- ============================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'success', 'error')),
  is_read BOOLEAN DEFAULT false,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES profiles(id),
  push_enabled BOOLEAN DEFAULT true,
  email_enabled BOOLEAN DEFAULT false,
  sms_enabled BOOLEAN DEFAULT false,
  waste_updates BOOLEAN DEFAULT true,
  payment_updates BOOLEAN DEFAULT true,
  promotion_updates BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 13. CHAT / MESSAGING
-- ============================================
CREATE TABLE chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  waste_request_id UUID REFERENCES waste_requests(id),
  user1_id UUID NOT NULL REFERENCES profiles(id),
  user2_id UUID NOT NULL REFERENCES profiles(id),
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 14. SUPPORT TICKETS
-- ============================================
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id),
  subject TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'OTHER' CHECK (category IN ('PAYMENT', 'COLLECTION', 'ACCOUNT', 'TECHNICAL', 'OTHER')),
  priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE ticket_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  content TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 15. ILLEGAL DUMPING REPORTS
-- ============================================
CREATE TABLE illegal_dumping_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id TEXT UNIQUE NOT NULL,
  reporter_id UUID NOT NULL REFERENCES profiles(id),
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  description TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')),
  assigned_to UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE report_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES illegal_dumping_reports(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 16. RECYCLING
-- ============================================
CREATE TABLE recycling_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recycler_id UUID NOT NULL REFERENCES profiles(id),
  material_type TEXT NOT NULL,
  quantity_kg DOUBLE PRECISION NOT NULL,
  price_per_kg DOUBLE PRECISION NOT NULL,
  total_price DOUBLE PRECISION GENERATED ALWAYS AS (quantity_kg * price_per_kg) STORED,
  status TEXT NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'SOLD', 'EXPIRED')),
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE recycling_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES recycling_offers(id),
  buyer_id UUID NOT NULL REFERENCES profiles(id),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  amount DOUBLE PRECISION NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 17. ROUTING
-- ============================================
CREATE TABLE collection_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collector_id UUID NOT NULL REFERENCES profiles(id),
  shift_id UUID REFERENCES collection_shifts(id),
  name TEXT,
  stops JSONB DEFAULT '[]',
  optimized_stops JSONB DEFAULT '[]',
  total_distance_km DOUBLE PRECISION,
  estimated_duration_minutes INTEGER,
  status TEXT NOT NULL DEFAULT 'PLANNED' CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 18. ADMIN SETTINGS
-- ============================================
CREATE TABLE admin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 19. AUDIT LOGS
-- ============================================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 20. FCM DEVICES
-- ============================================
CREATE TABLE fcm_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_zone ON profiles(zone_id);

CREATE INDEX idx_waste_requests_user ON waste_requests(user_id);
CREATE INDEX idx_waste_requests_status ON waste_requests(status);
CREATE INDEX idx_waste_requests_category ON waste_requests(category_id);
CREATE INDEX idx_waste_requests_collector ON waste_requests(assigned_collector_id);
CREATE INDEX idx_waste_requests_zone ON waste_requests(zone_id);
CREATE INDEX idx_waste_requests_created ON waste_requests(created_at DESC);

CREATE INDEX idx_collection_assignments_collector ON collection_assignments(collector_id);
CREATE INDEX idx_collection_assignments_status ON collection_assignments(status);

CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

CREATE INDEX idx_rating_reviews_to_user ON rating_reviews(to_user_id);

CREATE INDEX idx_support_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);

CREATE INDEX idx_illegal_dumping_status ON illegal_dumping_reports(status);
CREATE INDEX idx_illegal_dumping_severity ON illegal_dumping_reports(severity);

CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_request_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE rating_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE illegal_dumping_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE recycling_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE recycling_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_devices ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Profiles: users can read all, update own
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Waste Requests: users see own, collectors see assigned, admins see all
CREATE POLICY "Users view own waste requests" ON waste_requests FOR SELECT USING (
  auth.uid() = user_id OR auth.uid() = assigned_collector_id
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('ADMINISTRATOR', 'AUTHORITY'))
);
CREATE POLICY "Users create own waste requests" ON waste_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own waste requests" ON waste_requests FOR UPDATE USING (
  auth.uid() = user_id OR auth.uid() = assigned_collector_id
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('ADMINISTRATOR', 'AUTHORITY'))
);

-- Waste Request Photos
CREATE POLICY "Photos viewable by request owner" ON waste_request_photos FOR SELECT USING (
  EXISTS (SELECT 1 FROM waste_requests WHERE id = waste_request_id AND (user_id = auth.uid() OR assigned_collector_id = auth.uid()))
);
CREATE POLICY "Users can add photos to own requests" ON waste_request_photos FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM waste_requests WHERE id = waste_request_id AND user_id = auth.uid())
);

-- Payments
CREATE POLICY "Users view own payments" ON payments FOR SELECT USING (
  auth.uid() = user_id
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'ADMINISTRATOR')
);
CREATE POLICY "Users create own payments" ON payments FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Notifications
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT WITH CHECK (true);

-- Chat
CREATE POLICY "Users view own conversations" ON chat_conversations FOR SELECT USING (
  auth.uid() = user1_id OR auth.uid() = user2_id
);
CREATE POLICY "Users view own messages" ON chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_conversations WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);
CREATE POLICY "Users send messages in own conversations" ON chat_messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (SELECT 1 FROM chat_conversations WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);

-- Support Tickets
CREATE POLICY "Users view own tickets" ON support_tickets FOR SELECT USING (
  auth.uid() = user_id
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('ADMINISTRATOR', 'AUTHORITY'))
);
CREATE POLICY "Users create own tickets" ON support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ticket Messages
CREATE POLICY "Users view ticket messages" ON ticket_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM support_tickets WHERE id = ticket_id AND user_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('ADMINISTRATOR', 'AUTHORITY'))
);

-- Illegal Dumping Reports
CREATE POLICY "Reports viewable by everyone" ON illegal_dumping_reports FOR SELECT USING (true);
CREATE POLICY "Users create reports" ON illegal_dumping_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Zones
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Zones viewable by everyone" ON zones FOR SELECT USING (true);

-- Waste Categories
ALTER TABLE waste_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories viewable by everyone" ON waste_categories FOR SELECT USING (true);

-- Reward Wallets
CREATE POLICY "Users view own wallet" ON reward_wallets FOR SELECT USING (auth.uid() = user_id);

-- Rating Reviews
CREATE POLICY "Reviews viewable by everyone" ON rating_reviews FOR SELECT USING (is_public = true OR auth.uid() = from_user_id OR auth.uid() = to_user_id);
CREATE POLICY "Users create reviews" ON rating_reviews FOR INSERT WITH CHECK (auth.uid() = from_user_id);

-- Collection Assignments
CREATE POLICY "Collectors view own assignments" ON collection_assignments FOR SELECT USING (
  auth.uid() = collector_id
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('ADMINISTRATOR', 'AUTHORITY'))
);

-- Live Locations
CREATE POLICY "Collectors manage own location" ON live_locations FOR ALL USING (auth.uid() = collector_id);

-- Recycling
CREATE POLICY "Recycling offers viewable by everyone" ON recycling_offers FOR SELECT USING (true);
CREATE POLICY "Recyclers manage own offers" ON recycling_offers FOR ALL USING (auth.uid() = recycler_id);
