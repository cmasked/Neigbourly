-- ============================================================
-- Neighborly — Seed Data
-- ============================================================

-- Communities
INSERT INTO communities (id, name, slug, description, is_active) VALUES
('c1000000-0000-0000-0000-000000000001', 'Maple Heights Residency', 'maple-heights', 'A gated residential community in downtown.', TRUE),
('c1000000-0000-0000-0000-000000000002', 'Sunrise Tech Park', 'sunrise-tech', 'Co-working community for tech professionals.', TRUE),
('c1000000-0000-0000-0000-000000000003', 'Green Valley Society', 'green-valley', 'Eco-friendly suburban neighborhood.', TRUE);

-- Users (password is "password123" hashed with bcrypt)
INSERT INTO users (id, community_id, email, password_hash, first_name, last_name, phone, role, verification_status) VALUES
-- Maple Heights users
('u1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'alice@maple.com', '$2b$12$LJ3m4ys3Lz0QqV9xKn2rCOZvGqJp5Yw0RBfJxXQ1Ds5V5Yw0RBfJx', 'Alice', 'Johnson', '+1234567001', 'admin', 'verified'),
('u1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'bob@maple.com', '$2b$12$LJ3m4ys3Lz0QqV9xKn2rCOZvGqJp5Yw0RBfJxXQ1Ds5V5Yw0RBfJx', 'Bob', 'Smith', '+1234567002', 'user', 'verified'),
('u1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000001', 'carol@maple.com', '$2b$12$LJ3m4ys3Lz0QqV9xKn2rCOZvGqJp5Yw0RBfJxXQ1Ds5V5Yw0RBfJx', 'Carol', 'Davis', '+1234567003', 'user', 'verified'),
-- Sunrise Tech users
('u1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000002', 'dave@sunrise.com', '$2b$12$LJ3m4ys3Lz0QqV9xKn2rCOZvGqJp5Yw0RBfJxXQ1Ds5V5Yw0RBfJx', 'Dave', 'Wilson', '+1234567004', 'admin', 'verified'),
('u1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000002', 'eve@sunrise.com', '$2b$12$LJ3m4ys3Lz0QqV9xKn2rCOZvGqJp5Yw0RBfJxXQ1Ds5V5Yw0RBfJx', 'Eve', 'Brown', '+1234567005', 'user', 'verified'),
-- Super admin
('u1000000-0000-0000-0000-000000000099', 'c1000000-0000-0000-0000-000000000001', 'superadmin@neighborly.com', '$2b$12$LJ3m4ys3Lz0QqV9xKn2rCOZvGqJp5Yw0RBfJxXQ1Ds5V5Yw0RBfJx', 'Super', 'Admin', '+1234567099', 'super_admin', 'verified');

-- Items (Maple Heights)
INSERT INTO items (id, owner_id, community_id, title, description, category, daily_rate, weekly_rate, deposit_required, status) VALUES
('i1000000-0000-0000-0000-000000000001', 'u1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'Power Drill Set', 'Bosch 18V cordless drill with 50-piece bit set. Great for home projects.', 'tools', 15.00, 80.00, 50.00, 'active'),
('i1000000-0000-0000-0000-000000000002', 'u1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'Camping Tent 4-Person', 'Coleman 4-person dome tent, waterproof with carrying bag.', 'outdoor', 25.00, 140.00, 75.00, 'active'),
('i1000000-0000-0000-0000-000000000003', 'u1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'Stand Mixer', 'KitchenAid 5-quart stand mixer in red. Includes 3 attachments.', 'kitchen', 20.00, 110.00, 100.00, 'active'),
('i1000000-0000-0000-0000-000000000004', 'u1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000001', 'Projector HD', 'Epson HD projector 3200 lumens. HDMI and USB inputs.', 'electronics', 35.00, 200.00, 150.00, 'active');

-- Items (Sunrise Tech)
INSERT INTO items (id, owner_id, community_id, title, description, category, daily_rate, weekly_rate, deposit_required, status) VALUES
('i1000000-0000-0000-0000-000000000005', 'u1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000002', 'Standing Desk Converter', 'Adjustable standing desk riser, fits dual monitors.', 'office', 10.00, 55.00, 60.00, 'active'),
('i1000000-0000-0000-0000-000000000006', 'u1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000002', 'Mechanical Keyboard', 'Cherry MX Brown switches, backlit, USB-C.', 'electronics', 8.00, 40.00, 40.00, 'active');

-- Item Availability
INSERT INTO item_availability (id, item_id, start_date, end_date, is_blocked, reason) VALUES
('a1000000-0000-0000-0000-000000000001', 'i1000000-0000-0000-0000-000000000001', '2026-04-20', '2026-12-31', FALSE, NULL),
('a1000000-0000-0000-0000-000000000002', 'i1000000-0000-0000-0000-000000000002', '2026-05-01', '2026-09-30', FALSE, NULL),
('a1000000-0000-0000-0000-000000000003', 'i1000000-0000-0000-0000-000000000003', '2026-04-20', '2026-12-31', FALSE, NULL),
('a1000000-0000-0000-0000-000000000004', 'i1000000-0000-0000-0000-000000000004', '2026-04-20', '2026-12-31', FALSE, NULL);

-- Trust Scores (initial)
INSERT INTO trust_scores (id, user_id, community_id, score, last_calculated_at) VALUES
('t1000000-0000-0000-0000-000000000001', 'u1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 50.00, NOW()),
('t1000000-0000-0000-0000-000000000002', 'u1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 50.00, NOW()),
('t1000000-0000-0000-0000-000000000003', 'u1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000001', 50.00, NOW()),
('t1000000-0000-0000-0000-000000000004', 'u1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000002', 50.00, NOW()),
('t1000000-0000-0000-0000-000000000005', 'u1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000002', 50.00, NOW());
