-- V3__classification_and_policy_model.sql
-- Classifications and Versioned Recovery Policies with Intervention Matrix Seed Data

-- 1. Classifications table (UNIQUE payment_event_id: at most one classification per event)
CREATE TABLE classifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_event_id UUID NOT NULL REFERENCES payment_events(id) ON DELETE CASCADE,
    reason_code VARCHAR(50) NOT NULL,
    confidence NUMERIC(5, 4) NOT NULL CHECK (confidence >= 0.0 AND confidence <= 1.0),
    suggested_action VARCHAR(50) NOT NULL,
    model_name VARCHAR(100) NOT NULL DEFAULT 'llama-3.3-70b-versatile',
    raw_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_classifications_payment_event_id UNIQUE (payment_event_id)
);

CREATE INDEX idx_classifications_payment_event_id ON classifications(payment_event_id);
CREATE INDEX idx_classifications_reason_code ON classifications(reason_code);

-- 2. Recovery Policies table (Data-driven intervention matrix)
CREATE TABLE recovery_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reason_code VARCHAR(50) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    active BOOLEAN NOT NULL DEFAULT true,
    min_confidence NUMERIC(5, 4) NOT NULL DEFAULT 0.6000 CHECK (min_confidence >= 0.0 AND min_confidence <= 1.0),
    action VARCHAR(50) NOT NULL,
    max_attempts INT NOT NULL DEFAULT 0 CHECK (max_attempts >= 0),
    cooldown_seconds INT NOT NULL DEFAULT 0 CHECK (cooldown_seconds >= 0),
    amount_cap NUMERIC(15, 2) NOT NULL DEFAULT 20000.00 CHECK (amount_cap >= 0),
    escalate_after_attempts INT NOT NULL DEFAULT 0 CHECK (escalate_after_attempts >= 0),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_recovery_policies_reason_version UNIQUE (reason_code, version)
);

CREATE INDEX idx_recovery_policies_lookup ON recovery_policies(reason_code, active);

-- 3. Seed Intervention Matrix into recovery_policies (version = 1, active = true)
INSERT INTO recovery_policies (
    reason_code,
    version,
    active,
    min_confidence,
    action,
    max_attempts,
    cooldown_seconds,
    amount_cap,
    escalate_after_attempts,
    description
) VALUES
(
    'insufficient_funds',
    1,
    true,
    0.6000,
    'RETRY',
    3,
    60, -- 60 seconds demo cooldown (production: 6h)
    20000.00,
    3,
    'Retry up to 3 times with 60s cooldown for amounts under Rs20,000 when confidence >= 0.6'
),
(
    'network_timeout',
    1,
    true,
    0.6000,
    'RETRY',
    3,
    20, -- 20 seconds demo cooldown (production: 2m)
    20000.00,
    3,
    'Retry up to 3 times with 20s cooldown for transient network issues when confidence >= 0.6'
),
(
    'bank_declined',
    1,
    true,
    0.6000,
    'RETRY',
    2,
    90, -- 90 seconds demo cooldown (production: 24h)
    20000.00,
    2,
    'Retry up to 2 times with 90s cooldown when confidence >= 0.6'
),
(
    'card_expired',
    1,
    true,
    0.0000,
    'REQUEST_UPDATE',
    0,
    0,
    20000.00,
    0,
    'Card expired: do not retry, immediately request updated payment details from customer'
),
(
    'fraud_suspected',
    1,
    true,
    0.0000,
    'BLOCK',
    0,
    0,
    20000.00,
    0,
    'Suspected fraud: immediately block autonomous action and require human intervention'
),
(
    'other',
    1,
    true,
    0.0000,
    'ESCALATE',
    0,
    0,
    20000.00,
    0,
    'Unclassified or low confidence (< 0.6): immediately escalate to human review'
);
