-- ============================================================
-- Neighborly — Full MySQL 8.0+ Schema
-- Normalized to 3NF | InnoDB | utf8mb4
-- ============================================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- -----------------------------------------------------------
-- 1. COMMUNITIES
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS communities (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    logo_url VARCHAR(500),
    settings JSON DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_communities_slug (slug),
    INDEX idx_communities_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 2. USERS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY,
    community_id CHAR(36) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    avatar_url VARCHAR(500) DEFAULT NULL,
    role ENUM('user','admin','super_admin') NOT NULL DEFAULT 'user',
    verification_status ENUM('unverified','pending','verified','suspended','banned') NOT NULL DEFAULT 'unverified',
    kyc_document_ref VARCHAR(255) DEFAULT NULL,
    kyc_verified_at TIMESTAMP NULL DEFAULT NULL,
    refresh_token_hash VARCHAR(255) DEFAULT NULL,
    last_login_at TIMESTAMP NULL DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_users_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    UNIQUE KEY uq_users_email_community (email, community_id),
    INDEX idx_users_community (community_id),
    INDEX idx_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_verification (verification_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 3. ITEMS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS items (
    id CHAR(36) PRIMARY KEY,
    owner_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    weekly_rate DECIMAL(10,2) DEFAULT NULL,
    deposit_required DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    condition_description TEXT,
    image_urls JSON DEFAULT NULL,
    status ENUM('active','inactive','rented','removed') NOT NULL DEFAULT 'active',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_items_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_items_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    INDEX idx_items_community (community_id),
    INDEX idx_items_owner (owner_id),
    INDEX idx_items_category (category),
    INDEX idx_items_status (status),
    INDEX idx_items_daily_rate (daily_rate),
    FULLTEXT INDEX ft_items_search (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 4. ITEM AVAILABILITY
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS item_availability (
    id CHAR(36) PRIMARY KEY,
    item_id CHAR(36) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    reason VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_availability_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
    CONSTRAINT chk_dates CHECK (end_date >= start_date),
    INDEX idx_availability_item (item_id),
    INDEX idx_availability_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 5. RENTAL REQUESTS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS rental_requests (
    id CHAR(36) PRIMARY KEY,
    item_id CHAR(36) NOT NULL,
    borrower_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    status ENUM('pending','accepted','rejected','counter_proposed','expired','cancelled') NOT NULL DEFAULT 'pending',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    proposed_daily_rate DECIMAL(10,2) NOT NULL,
    message TEXT,
    counter_start_date DATE DEFAULT NULL,
    counter_end_date DATE DEFAULT NULL,
    counter_daily_rate DECIMAL(10,2) DEFAULT NULL,
    counter_message TEXT DEFAULT NULL,
    expires_at TIMESTAMP NULL DEFAULT NULL,
    responded_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_rr_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
    CONSTRAINT fk_rr_borrower FOREIGN KEY (borrower_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_rr_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    CONSTRAINT chk_rr_dates CHECK (end_date >= start_date),
    INDEX idx_rr_community (community_id),
    INDEX idx_rr_item (item_id),
    INDEX idx_rr_borrower (borrower_id),
    INDEX idx_rr_status (status),
    INDEX idx_rr_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 6. TRANSACTIONS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
    id CHAR(36) PRIMARY KEY,
    rental_request_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    owner_id CHAR(36) NOT NULL,
    borrower_id CHAR(36) NOT NULL,
    item_id CHAR(36) NOT NULL,
    status ENUM('booking_confirmed','payment_collected','item_picked_up','active','return_initiated','completed','cancelled') NOT NULL DEFAULT 'booking_confirmed',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    total_rental_fee DECIMAL(10,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    idempotency_key VARCHAR(255) NOT NULL,
    pickup_at TIMESTAMP NULL DEFAULT NULL,
    return_at TIMESTAMP NULL DEFAULT NULL,
    completed_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_txn_request FOREIGN KEY (rental_request_id) REFERENCES rental_requests(id) ON DELETE RESTRICT,
    CONSTRAINT fk_txn_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    CONSTRAINT fk_txn_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_txn_borrower FOREIGN KEY (borrower_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_txn_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
    UNIQUE KEY uq_txn_idempotency (idempotency_key),
    INDEX idx_txn_community (community_id),
    INDEX idx_txn_status (status),
    INDEX idx_txn_owner (owner_id),
    INDEX idx_txn_borrower (borrower_id),
    INDEX idx_txn_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 7. PAYMENTS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    payer_id CHAR(36) NOT NULL,
    payment_type ENUM('rental_fee','security_deposit','commission','refund') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    escrow_status ENUM('pending','held_in_escrow','released','refunded') NOT NULL DEFAULT 'pending',
    gateway_reference VARCHAR(255) DEFAULT NULL,
    gateway_provider VARCHAR(50) DEFAULT NULL,
    idempotency_key VARCHAR(255) NOT NULL,
    paid_at TIMESTAMP NULL DEFAULT NULL,
    released_at TIMESTAMP NULL DEFAULT NULL,
    refunded_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_pay_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pay_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pay_payer FOREIGN KEY (payer_id) REFERENCES users(id) ON DELETE RESTRICT,
    UNIQUE KEY uq_pay_idempotency (idempotency_key),
    INDEX idx_pay_transaction (transaction_id),
    INDEX idx_pay_community (community_id),
    INDEX idx_pay_escrow (escrow_status),
    INDEX idx_pay_type (payment_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 8. SECURITY DEPOSITS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS security_deposits (
    id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('held','partially_deducted','fully_deducted','released','refunded') NOT NULL DEFAULT 'held',
    deduction_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    deduction_reason TEXT DEFAULT NULL,
    released_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_dep_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_dep_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    UNIQUE KEY uq_dep_transaction (transaction_id),
    INDEX idx_dep_community (community_id),
    INDEX idx_dep_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 9. RETURN LOGS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS return_logs (
    id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    returned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    item_condition ENUM('excellent','good','fair','damaged','missing') NOT NULL DEFAULT 'good',
    condition_notes TEXT,
    photo_urls JSON DEFAULT NULL,
    is_late BOOLEAN NOT NULL DEFAULT FALSE,
    days_late INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ret_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ret_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    UNIQUE KEY uq_ret_transaction (transaction_id),
    INDEX idx_ret_community (community_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 10. DAMAGE REPORTS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS damage_reports (
    id CHAR(36) PRIMARY KEY,
    return_log_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    reporter_id CHAR(36) NOT NULL,
    description TEXT NOT NULL,
    evidence_urls JSON DEFAULT NULL,
    estimated_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status ENUM('reported','under_review','confirmed','dismissed') NOT NULL DEFAULT 'reported',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_dmg_return FOREIGN KEY (return_log_id) REFERENCES return_logs(id) ON DELETE RESTRICT,
    CONSTRAINT fk_dmg_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    CONSTRAINT fk_dmg_reporter FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE RESTRICT,
    INDEX idx_dmg_return (return_log_id),
    INDEX idx_dmg_community (community_id),
    INDEX idx_dmg_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 11. DISPUTES
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS disputes (
    id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36) NOT NULL,
    damage_report_id CHAR(36) DEFAULT NULL,
    community_id CHAR(36) NOT NULL,
    filed_by CHAR(36) NOT NULL,
    status ENUM('open','under_review','resolved','escalated','closed') NOT NULL DEFAULT 'open',
    reason TEXT NOT NULL,
    evidence_urls JSON DEFAULT NULL,
    verdict TEXT DEFAULT NULL,
    verdict_by CHAR(36) DEFAULT NULL,
    resolved_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_disp_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_disp_damage FOREIGN KEY (damage_report_id) REFERENCES damage_reports(id) ON DELETE SET NULL,
    CONSTRAINT fk_disp_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    CONSTRAINT fk_disp_filed_by FOREIGN KEY (filed_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_disp_verdict_by FOREIGN KEY (verdict_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_disp_community (community_id),
    INDEX idx_disp_transaction (transaction_id),
    INDEX idx_disp_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 12. REVIEWS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id CHAR(36) PRIMARY KEY,
    transaction_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    reviewer_id CHAR(36) NOT NULL,
    reviewee_id CHAR(36) NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_rev_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_rev_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    CONSTRAINT fk_rev_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_rev_reviewee FOREIGN KEY (reviewee_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT chk_rating CHECK (rating >= 1 AND rating <= 5),
    UNIQUE KEY uq_rev_txn_reviewer (transaction_id, reviewer_id),
    INDEX idx_rev_community (community_id),
    INDEX idx_rev_reviewee (reviewee_id),
    INDEX idx_rev_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 13. TRUST SCORES
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS trust_scores (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    score DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    total_rentals_completed INT NOT NULL DEFAULT 0,
    on_time_returns INT NOT NULL DEFAULT 0,
    late_returns INT NOT NULL DEFAULT 0,
    damage_reports_filed INT NOT NULL DEFAULT 0,
    disputes_lost INT NOT NULL DEFAULT 0,
    positive_reviews INT NOT NULL DEFAULT 0,
    negative_reviews INT NOT NULL DEFAULT 0,
    factors JSON DEFAULT NULL,
    last_calculated_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_ts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ts_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE,
    CONSTRAINT chk_score_range CHECK (score >= 0 AND score <= 100),
    UNIQUE KEY uq_ts_user_community (user_id, community_id),
    INDEX idx_ts_community (community_id),
    INDEX idx_ts_score (score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 14. NOTIFICATIONS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSON DEFAULT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE,
    INDEX idx_notif_user (user_id),
    INDEX idx_notif_community (community_id),
    INDEX idx_notif_read (is_read),
    INDEX idx_notif_type (type),
    INDEX idx_notif_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 15. CHAT MESSAGES
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
    id CHAR(36) PRIMARY KEY,
    sender_id CHAR(36) NOT NULL,
    receiver_id CHAR(36) NOT NULL,
    rental_request_id CHAR(36) DEFAULT NULL,
    community_id CHAR(36) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_chat_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_chat_receiver FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_chat_rr FOREIGN KEY (rental_request_id) REFERENCES rental_requests(id) ON DELETE SET NULL,
    CONSTRAINT fk_chat_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    INDEX idx_chat_community (community_id),
    INDEX idx_chat_sender (sender_id),
    INDEX idx_chat_receiver (receiver_id),
    INDEX idx_chat_rr (rental_request_id),
    INDEX idx_chat_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 16. ADMIN ACTIONS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_actions (
    id CHAR(36) PRIMARY KEY,
    admin_id CHAR(36) NOT NULL,
    community_id CHAR(36) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id CHAR(36) NOT NULL,
    reason TEXT,
    metadata JSON DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_aa_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_aa_community FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE RESTRICT,
    INDEX idx_aa_community (community_id),
    INDEX idx_aa_admin (admin_id),
    INDEX idx_aa_action (action_type),
    INDEX idx_aa_target (target_type, target_id),
    INDEX idx_aa_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- 17. DEPOSIT AUDIT LOGS
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS deposit_audit_logs (
    id CHAR(36) PRIMARY KEY,
    deposit_id CHAR(36) NOT NULL,
    action ENUM('held','partial_deduction','full_deduction','released','refunded') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    performed_by CHAR(36) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dal_deposit FOREIGN KEY (deposit_id) REFERENCES security_deposits(id) ON DELETE RESTRICT,
    CONSTRAINT fk_dal_performer FOREIGN KEY (performed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_dal_deposit (deposit_id),
    INDEX idx_dal_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
