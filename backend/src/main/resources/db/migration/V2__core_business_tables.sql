-- V2__core_business_tables.sql
-- Core business tables: customers, recovery_batches, payment_events

-- 1. Customers
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_customer_id VARCHAR(100) UNIQUE,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Recovery Batches
CREATE TABLE recovery_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    total_events INT NOT NULL DEFAULT 0,
    at_risk_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    diagnosed_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    intervention_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    recovered_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    recovery_rate NUMERIC(7, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 3. Payment Events (with UNIQUE event_id for strict idempotency)
CREATE TABLE payment_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id VARCHAR(100) NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES recovery_batches(id) ON DELETE SET NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    payment_method VARCHAR(50) NOT NULL DEFAULT 'CARD',
    raw_failure_code VARCHAR(100),
    raw_failure_message TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'INGESTED',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_payment_events_event_id UNIQUE (event_id)
);

-- Indexes for efficient queries and batch funnel processing
CREATE INDEX idx_payment_events_event_id ON payment_events(event_id);
CREATE INDEX idx_payment_events_customer_id ON payment_events(customer_id);
CREATE INDEX idx_payment_events_batch_id ON payment_events(batch_id);
CREATE INDEX idx_payment_events_status ON payment_events(status);
