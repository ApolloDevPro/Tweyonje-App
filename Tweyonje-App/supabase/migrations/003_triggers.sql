-- ============================================
-- DATABASE TRIGGERS - User Profile Sync
-- Run AFTER 001_initial_schema.sql
-- ============================================

-- ============================================
-- 1. FUNCTION: Create profile on signup
-- ============================================
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
  
  -- Also create a reward wallet for the new user
  INSERT INTO public.reward_wallets (user_id, balance, total_earned, total_redeemed, tier)
  VALUES (
    NEW.id,
    0,
    0,
    0,
    'BRONZE'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 2. TRIGGER: Call function on user creation
-- ============================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 3. FUNCTION: Sync profile updates from auth.users
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS trigger AS $$
BEGIN
  UPDATE public.profiles
  SET
    email = NEW.email,
    full_name = COALESCE(NEW.raw_user_meta_data->>'full_name', profiles.full_name),
    first_name = COALESCE(NEW.raw_user_meta_data->>'first_name', profiles.first_name),
    last_name = COALESCE(NEW.raw_user_meta_data->>'last_name', profiles.last_name),
    phone = COALESCE(NEW.raw_user_meta_data->>'phone', profiles.phone),
    updated_at = NOW()
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. TRIGGER: Call function on user update
-- ============================================
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_update();

-- ============================================
-- 5. FUNCTION: Update updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. TRIGGERS: Auto-update updated_at columns
-- ============================================
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_waste_requests_updated_at
  BEFORE UPDATE ON waste_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_reward_wallets_updated_at
  BEFORE UPDATE ON reward_wallets
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_admin_settings_updated_at
  BEFORE UPDATE ON admin_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 7. FUNCTION: Auto-generate reference IDs
-- ============================================
CREATE OR REPLACE FUNCTION public.generate_reference_id(prefix TEXT)
RETURNS text AS $$
DECLARE
  new_id TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    new_id := prefix || '-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
    
    SELECT EXISTS(
      SELECT 1 FROM waste_requests WHERE reference_id = new_id
      UNION
      SELECT 1 FROM payments WHERE reference_id = new_id
      UNION
      SELECT 1 FROM illegal_dumping_reports WHERE reference_id = new_id
      UNION
      SELECT 1 FROM collection_assignments WHERE reference_id = new_id
    ) INTO exists;
    
    IF NOT exists THEN
      RETURN new_id;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. FUNCTION: Update waste request reference ID
-- ============================================
CREATE OR REPLACE FUNCTION public.set_waste_request_reference()
RETURNS trigger AS $$
BEGIN
  IF NEW.reference_id IS NULL OR NEW.reference_id = '' THEN
    NEW.reference_id := public.generate_reference_id('WR');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_waste_request_reference
  BEFORE INSERT ON waste_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_waste_request_reference();

-- ============================================
-- 9. FUNCTION: Update payment reference ID
-- ============================================
CREATE OR REPLACE FUNCTION public.set_payment_reference()
RETURNS trigger AS $$
BEGIN
  IF NEW.reference_id IS NULL OR NEW.reference_id = '' THEN
    NEW.reference_id := public.generate_reference_id('PAY');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_payment_reference
  BEFORE INSERT ON payments
  FOR EACH ROW EXECUTE FUNCTION public.set_payment_reference();

-- ============================================
-- 10. FUNCTION: Update report reference ID
-- ============================================
CREATE OR REPLACE FUNCTION public.set_report_reference()
RETURNS trigger AS $$
BEGIN
  IF NEW.reference_id IS NULL OR NEW.reference_id = '' THEN
    NEW.reference_id := public.generate_reference_id('RPT');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_report_reference
  BEFORE INSERT ON illegal_dumping_reports
  FOR EACH ROW EXECUTE FUNCTION public.set_report_reference();

-- ============================================
-- 11. FUNCTION: Update assignment reference ID
-- ============================================
CREATE OR REPLACE FUNCTION public.set_assignment_reference()
RETURNS trigger AS $$
BEGIN
  IF NEW.reference_id IS NULL OR NEW.reference_id = '' THEN
    NEW.reference_id := public.generate_reference_id('ASN');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_assignment_reference
  BEFORE INSERT ON collection_assignments
  FOR EACH ROW EXECUTE FUNCTION public.set_assignment_reference();

-- ============================================
-- 12. FUNCTION: Update invoice number
-- ============================================
CREATE OR REPLACE FUNCTION public.set_invoice_number()
RETURNS trigger AS $$
BEGIN
  IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
    NEW.invoice_number := 'INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_invoice_number
  BEFORE INSERT ON invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_invoice_number();

-- ============================================
-- 13. FUNCTION: Update ticket number
-- ============================================
CREATE OR REPLACE FUNCTION public.set_ticket_number()
RETURNS trigger AS $$
BEGIN
  IF NEW.ticket_number IS NULL OR NEW.ticket_number = '' THEN
    NEW.ticket_number := 'TKT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_ticket_number
  BEFORE INSERT ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.set_ticket_number();

-- ============================================
-- 14. FUNCTION: Award eco points on collection
-- ============================================
CREATE OR REPLACE FUNCTION public.award_eco_points()
RETURNS trigger AS $$
DECLARE
  points_to_award INTEGER;
BEGIN
  -- Only award points when status changes to COMPLETED
  IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
    -- Calculate points based on actual weight and category base points
    SELECT COALESCE(CEIL(NEW.actual_weight_kg * wc.base_eco_points), 0)
    INTO points_to_award
    FROM waste_requests wr
    JOIN waste_categories wc ON wr.category_id = wc.id
    WHERE wr.id = NEW.waste_request_id;
    
    -- Award points to user
    IF points_to_award > 0 THEN
      UPDATE reward_wallets
      SET 
        balance = balance + points_to_award,
        total_earned = total_earned + points_to_award,
        updated_at = NOW()
      WHERE user_id = (
        SELECT user_id FROM waste_requests WHERE id = NEW.waste_request_id
      );
      
      -- Update waste request with awarded points
      UPDATE waste_requests
      SET eco_points_awarded = points_to_award
      WHERE id = NEW.waste_request_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER award_eco_points
  AFTER UPDATE ON collection_assignments
  FOR EACH ROW EXECUTE FUNCTION public.award_eco_points();

-- ============================================
-- 15. FUNCTION: Update chat conversation last message
-- ============================================
CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS trigger AS $$
BEGIN
  UPDATE chat_conversations
  SET 
    last_message = NEW.content,
    last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chat_last_message
  AFTER INSERT ON chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.update_chat_last_message();
