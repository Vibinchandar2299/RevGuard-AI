-- V4__recovery_and_audit_persistence.sql
-- Recovery actions, retry attempts, recovery messages, and audit log

-- 1. Recovery Actions (Decision Engine outcomes, tracking which policy_version was active)
CREATE TABLE recovery_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_event_id UUID NOT NULL REFERENCES payment_events(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    policy_version INT NOT NULL DEFAULT 1,
    policy_reason_code VARCHAR(50) NOT NULL,
    decision_reason TEXT NOT NULL,
    authorized_amount NUMERIC(15, 2),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recovery_actions_event_id ON recovery_actions(payment_event_id);
CREATE INDEX idx_recovery_actions_type ON recovery_actions(action_type);

-- 2. Retry Attempts (Pluggable executor outcomes with strict UNIQUE attempt_number constraint)
CREATE TABLE retry_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_event_id UUID NOT NULL REFERENCES payment_events(id) ON DELETE CASCADE,
    attempt_number INT NOT NULL CHECK (attempt_number >= 1),
    executor_type VARCHAR(50) NOT NULL, -- 'MOCK' or 'RAZORPAY'
    status VARCHAR(50) NOT NULL, -- 'SUCCESS', 'FAILED', 'PENDING'
    gateway_reference_id VARCHAR(100),
    error_message TEXT,
    attempted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_retry_attempts_event_attempt UNIQUE (payment_event_id, attempt_number)
);

CREATE INDEX idx_retry_attempts_event_id ON retry_attempts(payment_event_id);
CREATE INDEX idx_retry_attempts_status ON retry_attempts(status);

-- 3. Recovery Messages (AI-drafted customer recovery communications)
CREATE TABLE recovery_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_event_id UUID NOT NULL REFERENCES payment_events(id) ON DELETE CASCADE,
    channel VARCHAR(50) NOT NULL DEFAULT 'EMAIL',
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    body TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFTED', -- 'DRAFTED', 'SENT', 'REJECTED'
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_recovery_messages_status CHECK (status IN ('DRAFTED', 'SENT', 'REJECTED'))
);

CREATE INDEX idx_recovery_messages_event_id ON recovery_messages(payment_event_id);
CREATE INDEX idx_recovery_messages_status ON recovery_messages(status);

-- 4. Audit Log (Deterministic chronological trail of every system/actor decision)
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_event_id UUID REFERENCES payment_events(id) ON DELETE SET NULL,
    actor VARCHAR(50) NOT NULL, -- 'SYSTEM', 'LLM', 'POLICY_ENGINE', 'HUMAN'
    action VARCHAR(100) NOT NULL,
    reason TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_audit_log_actor CHECK (actor IN ('SYSTEM', 'LLM', 'POLICY_ENGINE', 'HUMAN'))
);

CREATE INDEX idx_audit_log_event_id ON audit_log(payment_event_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);
CREATE INDEX idx_audit_log_actor ON audit_log(actor);
