-- ============================================
-- SEED DATA - Tweyonje Smart Waste Management
-- Run AFTER 001_initial_schema.sql
-- ============================================

-- ============================================
-- 1. ZONES (Kampala & surrounding areas)
-- ============================================
INSERT INTO zones (name, code, region, description) VALUES
('Central Zone', 'CEN-01', 'Kampala', 'Central Business District and surrounding areas'),
('Kawempe Zone', 'KAW-01', 'Kawempe', 'Kawempe Division'),
('Makindye Zone', 'MAK-01', 'Makindye', 'Makindye Division'),
('Nakawa Zone', 'NAK-01', 'Nakawa', 'Nakawa Division'),
('Rubaga Zone', 'RUB-01', 'Rubaga', 'Rubaga Division'),
('Entebbe Zone', 'ENT-01', 'Wakiso', 'Entebbe Municipality'),
('Mukono Zone', 'MUK-01', 'Mukono', 'Mukono Municipality');

-- ============================================
-- 2. WASTE CATEGORIES
-- ============================================
INSERT INTO waste_categories (name, slug, description, icon, is_hazardous, default_price_per_kg, base_eco_points) VALUES
('Organic Waste', 'organic', 'Food scraps, garden waste, biodegradable materials', '🍃', false, 500, 10),
('Plastic', 'plastic', 'Bottles, bags, containers, packaging', '♻️', false, 1000, 20),
('Paper & Cardboard', 'paper', 'Newspapers, boxes, office paper, magazines', '📄', false, 800, 15),
('Glass', 'glass', 'Bottles, jars, broken glass', '🫙', false, 1200, 25),
('Metal', 'metal', 'Cans, scrap metal, aluminum, iron', '🔧', false, 1500, 30),
('Electronic Waste', 'e-waste', 'Batteries, phones, cables, appliances', '📱', true, 2000, 40),
('Hazardous Waste', 'hazardous', 'Chemicals, paint, medical waste, pesticides', '⚠️', true, 3000, 50),
('Mixed Waste', 'mixed', 'General household waste, non-recyclable', '🗑️', false, 300, 5),
('Textiles', 'textiles', 'Old clothes, fabrics, shoes', '👕', false, 700, 12),
('Construction Debris', 'construction', 'Bricks, concrete, rubble, sand', '🏗️', false, 2000, 35);

-- ============================================
-- 3. REWARD TIERS
-- ============================================
INSERT INTO reward_tiers (name, min_points, max_points, badge, benefits) VALUES
('Bronze', 0, 499, '🥉', '["Basic waste collection", "Standard response time"]'),
('Silver', 500, 1499, '🥈', '["Priority scheduling", "10% discount on fees", "Monthly reports"]'),
('Gold', 1500, 4999, '🥇', '["Free monthly collection", "5% cashback", "VIP support", "Eco-certificates"]'),
('Platinum', 5000, NULL, '💎', '["Unlimited free collection", "15% cashback", "Dedicated agent", "Community recognition", "Partnership rewards"]');

-- ============================================
-- 4. ADMIN SETTINGS
-- ============================================
INSERT INTO admin_settings (key, value, description) VALUES
('platform_name', '"Tweyonje"', 'Platform display name'),
('currency', '"UGX"', 'Default currency'),
('min_pickup_weight_kg', '1', 'Minimum weight for pickup request'),
('max_pickup_weight_kg', '500', 'Maximum weight per request'),
('eco_points_per_kg', '10', 'Base eco points per kg collected'),
('payment_methods', '["MTN_MOMO", "AIRTEL_MONEY", "CASH"]', 'Available payment methods'),
('notification_enabled', 'true', 'Global notification toggle'),
('maintenance_mode', 'false', 'Platform maintenance mode'),
('auto_assign_collectors', 'true', 'Automatic job assignment'),
('max_distance_km', '50', 'Maximum service distance from zone');

-- ============================================
-- 5. SAMPLE USER (for testing - password: test123456)
-- Note: This user must be created via Supabase Auth first
-- The profile will be created via trigger or manually
-- ============================================

-- Sample waste requests (will fail without users - uncomment after creating users)
-- INSERT INTO waste_requests (reference_id, user_id, category_id, pickup_address, latitude, longitude, estimated_weight_kg, status, estimated_price) VALUES
-- ('WR-2026-001', 'USER_UUID_HERE', (SELECT id FROM waste_categories WHERE slug = 'plastic'), 'Plot 123, Kampala Road', 0.3476, 32.5825, 25, 'PENDING', 25000),
-- ('WR-2026-002', 'USER_UUID_HERE', (SELECT id FROM waste_categories WHERE slug = 'organic'), '45 Colony Lane, Makerere', 0.3350, 32.5690, 15, 'ASSIGNED', 7500),
-- ('WR-2026-003', 'USER_UUID_HERE', (SELECT id FROM waste_categories WHERE slug = 'e-waste'), '78 Nkrumah Road, Entebbe', 0.0563, 32.4622, 5, 'COMPLETED', 10000);

-- ============================================
-- 6. VERIFICATION QUERIES
-- ============================================
-- Run these after seeding to verify:

-- SELECT 'Zones' as table_name, COUNT(*) as count FROM zones
-- UNION ALL
-- SELECT 'Waste Categories', COUNT(*) FROM waste_categories
-- UNION ALL
-- SELECT 'Reward Tiers', COUNT(*) FROM reward_tiers
-- UNION ALL
-- SELECT 'Admin Settings', COUNT(*) FROM admin_settings;
