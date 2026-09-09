-- V5__seed_synthetic_recovery_batch.sql
-- Seeds 100 realistic synthetic payment events grouped into one recovery batch
-- Money-weighted recovery rate: ~69.09% (within the 65-75% target range)

DO $$
DECLARE
    v_batch_id UUID := 'b0000000-0000-0000-0000-000000000001'::UUID;
    v_cust_ids UUID[] := ARRAY[
        'c0000000-0000-0000-0000-000000000001'::UUID,
        'c0000000-0000-0000-0000-000000000002'::UUID,
        'c0000000-0000-0000-0000-000000000003'::UUID,
        'c0000000-0000-0000-0000-000000000004'::UUID,
        'c0000000-0000-0000-0000-000000000005'::UUID,
        'c0000000-0000-0000-0000-000000000006'::UUID,
        'c0000000-0000-0000-0000-000000000007'::UUID,
        'c0000000-0000-0000-0000-000000000008'::UUID,
        'c0000000-0000-0000-0000-000000000009'::UUID,
        'c0000000-0000-0000-0000-000000000010'::UUID,
        'c0000000-0000-0000-0000-000000000011'::UUID,
        'c0000000-0000-0000-0000-000000000012'::UUID,
        'c0000000-0000-0000-0000-000000000013'::UUID,
        'c0000000-0000-0000-0000-000000000014'::UUID,
        'c0000000-0000-0000-0000-000000000015'::UUID,
        'c0000000-0000-0000-0000-000000000016'::UUID,
        'c0000000-0000-0000-0000-000000000017'::UUID,
        'c0000000-0000-0000-0000-000000000018'::UUID,
        'c0000000-0000-0000-0000-000000000019'::UUID,
        'c0000000-0000-0000-0000-000000000020'::UUID
    ];
    v_event_id UUID;
    v_cust_id UUID;
BEGIN
    -- 1. Insert Customers
    INSERT INTO customers (id, external_customer_id, email, name, phone) VALUES
        (v_cust_ids[1], 'CUST-IN-001', 'aarav.sharma@example.com', 'Aarav Sharma', '+919876543201'),
        (v_cust_ids[2], 'CUST-IN-002', 'priya.patel@example.com', 'Priya Patel', '+919876543202'),
        (v_cust_ids[3], 'CUST-IN-003', 'rahul.verma@example.com', 'Rahul Verma', '+919876543203'),
        (v_cust_ids[4], 'CUST-IN-004', 'ananya.iyer@example.com', 'Ananya Iyer', '+919876543204'),
        (v_cust_ids[5], 'CUST-IN-005', 'vikram.singh@example.com', 'Vikram Singh', '+919876543205'),
        (v_cust_ids[6], 'CUST-IN-006', 'sneha.reddy@example.com', 'Sneha Reddy', '+919876543206'),
        (v_cust_ids[7], 'CUST-IN-007', 'rohan.nair@example.com', 'Rohan Nair', '+919876543207'),
        (v_cust_ids[8], 'CUST-IN-008', 'pooja.gupta@example.com', 'Pooja Gupta', '+919876543208'),
        (v_cust_ids[9], 'CUST-IN-009', 'karthik.menon@example.com', 'Karthik Menon', '+919876543209'),
        (v_cust_ids[10], 'CUST-IN-010', 'divya.joshi@example.com', 'Divya Joshi', '+919876543210'),
        (v_cust_ids[11], 'CUST-IN-011', 'aditya.rao@example.com', 'Aditya Rao', '+919876543211'),
        (v_cust_ids[12], 'CUST-IN-012', 'meera.kulkarni@example.com', 'Meera Kulkarni', '+919876543212'),
        (v_cust_ids[13], 'CUST-IN-013', 'suresh.kumar@example.com', 'Suresh Kumar', '+919876543213'),
        (v_cust_ids[14], 'CUST-IN-014', 'ritu.agarwal@example.com', 'Ritu Agarwal', '+919876543214'),
        (v_cust_ids[15], 'CUST-IN-015', 'manoj.pillai@example.com', 'Manoj Pillai', '+919876543215'),
        (v_cust_ids[16], 'CUST-IN-016', 'neha.choudhury@example.com', 'Neha Choudhury', '+919876543216'),
        (v_cust_ids[17], 'CUST-IN-017', 'sanjay.deshmukh@example.com', 'Sanjay Deshmukh', '+919876543217'),
        (v_cust_ids[18], 'CUST-IN-018', 'kavita.bhat@example.com', 'Kavita Bhat', '+919876543218'),
        (v_cust_ids[19], 'CUST-IN-019', 'arjun.mukherjee@example.com', 'Arjun Mukherjee', '+919876543219'),
        (v_cust_ids[20], 'CUST-IN-020', 'shreya.das@example.com', 'Shreya Das', '+919876543220')
    ON CONFLICT (id) DO NOTHING;

    -- 2. Insert Recovery Batch
    INSERT INTO recovery_batches (
        id, batch_name, status, total_events, at_risk_amount, diagnosed_amount, intervention_amount, recovered_amount, recovery_rate, completed_at
    ) VALUES (
        v_batch_id, 'BATCH-2026-SYNTH-01', 'COMPLETED', 100, 511870.00, 511870.00, 459370.00, 353640.00, 69.09, CURRENT_TIMESTAMP
    );

    -- Event 1: evt_synth_001 (insufficient_funds, Rs 3620.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000001'::UUID;
    v_cust_id := v_cust_ids[2];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_001', v_cust_id, v_batch_id, 3620.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 3620.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_001_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 2: evt_synth_002 (insufficient_funds, Rs 3740.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000002'::UUID;
    v_cust_id := v_cust_ids[3];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_002', v_cust_id, v_batch_id, 3740.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 3740.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_002_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 3: evt_synth_003 (insufficient_funds, Rs 3860.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000003'::UUID;
    v_cust_id := v_cust_ids[4];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_003', v_cust_id, v_batch_id, 3860.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 3860.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_003_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 4: evt_synth_004 (insufficient_funds, Rs 3980.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000004'::UUID;
    v_cust_id := v_cust_ids[5];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_004', v_cust_id, v_batch_id, 3980.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 3980.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_004_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 5: evt_synth_005 (insufficient_funds, Rs 4100.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000005'::UUID;
    v_cust_id := v_cust_ids[6];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_005', v_cust_id, v_batch_id, 4100.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4100.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_005_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 6: evt_synth_006 (insufficient_funds, Rs 4220.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000006'::UUID;
    v_cust_id := v_cust_ids[7];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_006', v_cust_id, v_batch_id, 4220.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4220.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_006_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 7: evt_synth_007 (insufficient_funds, Rs 4340.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000007'::UUID;
    v_cust_id := v_cust_ids[8];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_007', v_cust_id, v_batch_id, 4340.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4340.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_007_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 8: evt_synth_008 (insufficient_funds, Rs 4460.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000008'::UUID;
    v_cust_id := v_cust_ids[9];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_008', v_cust_id, v_batch_id, 4460.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4460.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_008_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 9: evt_synth_009 (insufficient_funds, Rs 4580.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000009'::UUID;
    v_cust_id := v_cust_ids[10];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_009', v_cust_id, v_batch_id, 4580.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4580.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_009_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 10: evt_synth_010 (insufficient_funds, Rs 4700.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000010'::UUID;
    v_cust_id := v_cust_ids[11];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_010', v_cust_id, v_batch_id, 4700.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4700.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_010_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 11: evt_synth_011 (insufficient_funds, Rs 4820.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000011'::UUID;
    v_cust_id := v_cust_ids[12];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_011', v_cust_id, v_batch_id, 4820.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4820.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_011_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 12: evt_synth_012 (insufficient_funds, Rs 4940.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000012'::UUID;
    v_cust_id := v_cust_ids[13];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_012', v_cust_id, v_batch_id, 4940.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4940.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_012_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 13: evt_synth_013 (insufficient_funds, Rs 5060.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000013'::UUID;
    v_cust_id := v_cust_ids[14];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_013', v_cust_id, v_batch_id, 5060.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5060.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_013_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 14: evt_synth_014 (insufficient_funds, Rs 5180.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000014'::UUID;
    v_cust_id := v_cust_ids[15];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_014', v_cust_id, v_batch_id, 5180.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5180.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_014_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 15: evt_synth_015 (insufficient_funds, Rs 5300.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000015'::UUID;
    v_cust_id := v_cust_ids[16];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_015', v_cust_id, v_batch_id, 5300.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5300.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_015_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 16: evt_synth_016 (insufficient_funds, Rs 5420.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000016'::UUID;
    v_cust_id := v_cust_ids[17];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_016', v_cust_id, v_batch_id, 5420.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5420.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_016_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 17: evt_synth_017 (insufficient_funds, Rs 5540.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000017'::UUID;
    v_cust_id := v_cust_ids[18];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_017', v_cust_id, v_batch_id, 5540.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5540.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_017_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 18: evt_synth_018 (insufficient_funds, Rs 5660.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000018'::UUID;
    v_cust_id := v_cust_ids[19];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_018', v_cust_id, v_batch_id, 5660.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5660.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_018_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 19: evt_synth_019 (insufficient_funds, Rs 5780.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000019'::UUID;
    v_cust_id := v_cust_ids[20];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_019', v_cust_id, v_batch_id, 5780.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5780.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_019_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 20: evt_synth_020 (insufficient_funds, Rs 5900.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000020'::UUID;
    v_cust_id := v_cust_ids[1];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_020', v_cust_id, v_batch_id, 5900.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5900.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_020_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 21: evt_synth_021 (insufficient_funds, Rs 6020.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000021'::UUID;
    v_cust_id := v_cust_ids[2];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_021', v_cust_id, v_batch_id, 6020.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6020.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_021_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 22: evt_synth_022 (insufficient_funds, Rs 6140.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000022'::UUID;
    v_cust_id := v_cust_ids[3];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_022', v_cust_id, v_batch_id, 6140.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6140.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_022_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 23: evt_synth_023 (insufficient_funds, Rs 6260.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000023'::UUID;
    v_cust_id := v_cust_ids[4];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_023', v_cust_id, v_batch_id, 6260.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6260.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_023_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 24: evt_synth_024 (insufficient_funds, Rs 6380.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000024'::UUID;
    v_cust_id := v_cust_ids[5];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_024', v_cust_id, v_batch_id, 6380.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6380.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_024_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 25: evt_synth_025 (insufficient_funds, Rs 6500.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000025'::UUID;
    v_cust_id := v_cust_ids[6];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_025', v_cust_id, v_batch_id, 6500.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6500.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_025_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 26: evt_synth_026 (insufficient_funds, Rs 6620.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000026'::UUID;
    v_cust_id := v_cust_ids[7];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_026', v_cust_id, v_batch_id, 6620.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6620.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_026_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 27: evt_synth_027 (insufficient_funds, Rs 6740.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000027'::UUID;
    v_cust_id := v_cust_ids[8];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_027', v_cust_id, v_batch_id, 6740.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6740.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_027_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 28: evt_synth_028 (insufficient_funds, Rs 6860.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000028'::UUID;
    v_cust_id := v_cust_ids[9];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_028', v_cust_id, v_batch_id, 6860.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6860.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_028_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 29: evt_synth_029 (insufficient_funds, Rs 6980.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000029'::UUID;
    v_cust_id := v_cust_ids[10];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_029', v_cust_id, v_batch_id, 6980.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 6980.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_029_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 30: evt_synth_030 (insufficient_funds, Rs 7100.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000030'::UUID;
    v_cust_id := v_cust_ids[11];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_030', v_cust_id, v_batch_id, 7100.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 7100.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_030_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 31: evt_synth_031 (insufficient_funds, Rs 7220.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000031'::UUID;
    v_cust_id := v_cust_ids[12];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_031', v_cust_id, v_batch_id, 7220.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 7220.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_031_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 32: evt_synth_032 (insufficient_funds, Rs 7340.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000032'::UUID;
    v_cust_id := v_cust_ids[13];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_032', v_cust_id, v_batch_id, 7340.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Insufficient funds in account', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8800, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.88,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.88');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 7340.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_032_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 33: evt_synth_033 (insufficient_funds, Rs 4640.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000033'::UUID;
    v_cust_id := v_cust_ids[14];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_033', v_cust_id, v_batch_id, 4640.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4640.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_033_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_033_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 34: evt_synth_034 (insufficient_funds, Rs 4720.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000034'::UUID;
    v_cust_id := v_cust_ids[15];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_034', v_cust_id, v_batch_id, 4720.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4720.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_034_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_034_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 35: evt_synth_035 (insufficient_funds, Rs 4800.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000035'::UUID;
    v_cust_id := v_cust_ids[16];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_035', v_cust_id, v_batch_id, 4800.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4800.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_035_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_035_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 36: evt_synth_036 (insufficient_funds, Rs 4880.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000036'::UUID;
    v_cust_id := v_cust_ids[17];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_036', v_cust_id, v_batch_id, 4880.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4880.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_036_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_036_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 37: evt_synth_037 (insufficient_funds, Rs 4960.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000037'::UUID;
    v_cust_id := v_cust_ids[18];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_037', v_cust_id, v_batch_id, 4960.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 4960.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_037_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_037_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 38: evt_synth_038 (insufficient_funds, Rs 5040.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000038'::UUID;
    v_cust_id := v_cust_ids[19];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_038', v_cust_id, v_batch_id, 5040.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5040.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_038_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_038_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 39: evt_synth_039 (insufficient_funds, Rs 5120.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000039'::UUID;
    v_cust_id := v_cust_ids[20];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_039', v_cust_id, v_batch_id, 5120.00, 'INR', 'UPI', 'ERR_INSUFFICIENT_FUNDS', 'Account balance low', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.8200, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.82,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.82');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'insufficient_funds', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60', 5120.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for insufficient_funds with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_039_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_039_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 40: evt_synth_040 (insufficient_funds, Rs 24000.00, status: ESCALATED)
    v_event_id := 'e0000000-0000-0000-0000-000000000040'::UUID;
    v_cust_id := v_cust_ids[1];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_040', v_cust_id, v_batch_id, 24000.00, 'INR', 'CARD', 'ERR_INSUFFICIENT_FUNDS', 'Balance below threshold for high-value txn', 'ESCALATED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'insufficient_funds', 0.9000, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"insufficient_funds","confidence":0.90,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as insufficient_funds with confidence 0.90');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'ESCALATE', 1, 'insufficient_funds', 'Amount Rs 24000.00 exceeds policy amount cap of Rs 20,000.00; autonomous action prohibited', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Amount Rs 24000.00 exceeds policy amount cap of Rs 20,000.00; autonomous action prohibited');
    -- Event 41: evt_synth_041 (network_timeout, Rs 4150.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000041'::UUID;
    v_cust_id := v_cust_ids[2];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_041', v_cust_id, v_batch_id, 4150.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 4150.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_041_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 42: evt_synth_042 (network_timeout, Rs 4300.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000042'::UUID;
    v_cust_id := v_cust_ids[3];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_042', v_cust_id, v_batch_id, 4300.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 4300.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_042_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 43: evt_synth_043 (network_timeout, Rs 4450.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000043'::UUID;
    v_cust_id := v_cust_ids[4];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_043', v_cust_id, v_batch_id, 4450.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 4450.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_043_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 44: evt_synth_044 (network_timeout, Rs 4600.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000044'::UUID;
    v_cust_id := v_cust_ids[5];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_044', v_cust_id, v_batch_id, 4600.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 4600.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_044_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 45: evt_synth_045 (network_timeout, Rs 4750.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000045'::UUID;
    v_cust_id := v_cust_ids[6];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_045', v_cust_id, v_batch_id, 4750.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 4750.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_045_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 46: evt_synth_046 (network_timeout, Rs 4900.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000046'::UUID;
    v_cust_id := v_cust_ids[7];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_046', v_cust_id, v_batch_id, 4900.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 4900.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_046_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 47: evt_synth_047 (network_timeout, Rs 5050.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000047'::UUID;
    v_cust_id := v_cust_ids[8];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_047', v_cust_id, v_batch_id, 5050.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5050.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_047_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 48: evt_synth_048 (network_timeout, Rs 5200.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000048'::UUID;
    v_cust_id := v_cust_ids[9];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_048', v_cust_id, v_batch_id, 5200.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5200.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_048_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 49: evt_synth_049 (network_timeout, Rs 5350.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000049'::UUID;
    v_cust_id := v_cust_ids[10];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_049', v_cust_id, v_batch_id, 5350.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5350.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_049_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 50: evt_synth_050 (network_timeout, Rs 5500.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000050'::UUID;
    v_cust_id := v_cust_ids[11];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_050', v_cust_id, v_batch_id, 5500.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5500.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_050_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 51: evt_synth_051 (network_timeout, Rs 5650.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000051'::UUID;
    v_cust_id := v_cust_ids[12];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_051', v_cust_id, v_batch_id, 5650.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5650.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_051_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 52: evt_synth_052 (network_timeout, Rs 5800.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000052'::UUID;
    v_cust_id := v_cust_ids[13];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_052', v_cust_id, v_batch_id, 5800.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5800.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_052_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 53: evt_synth_053 (network_timeout, Rs 5950.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000053'::UUID;
    v_cust_id := v_cust_ids[14];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_053', v_cust_id, v_batch_id, 5950.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 5950.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_053_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 54: evt_synth_054 (network_timeout, Rs 6100.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000054'::UUID;
    v_cust_id := v_cust_ids[15];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_054', v_cust_id, v_batch_id, 6100.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 6100.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_054_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 55: evt_synth_055 (network_timeout, Rs 6250.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000055'::UUID;
    v_cust_id := v_cust_ids[16];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_055', v_cust_id, v_batch_id, 6250.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 6250.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_055_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 56: evt_synth_056 (network_timeout, Rs 6400.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000056'::UUID;
    v_cust_id := v_cust_ids[17];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_056', v_cust_id, v_batch_id, 6400.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 6400.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_056_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 57: evt_synth_057 (network_timeout, Rs 6550.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000057'::UUID;
    v_cust_id := v_cust_ids[18];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_057', v_cust_id, v_batch_id, 6550.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 6550.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_057_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 58: evt_synth_058 (network_timeout, Rs 6700.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000058'::UUID;
    v_cust_id := v_cust_ids[19];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_058', v_cust_id, v_batch_id, 6700.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 6700.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_058_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 59: evt_synth_059 (network_timeout, Rs 6850.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000059'::UUID;
    v_cust_id := v_cust_ids[20];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_059', v_cust_id, v_batch_id, 6850.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 6850.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_059_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 60: evt_synth_060 (network_timeout, Rs 7000.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000060'::UUID;
    v_cust_id := v_cust_ids[1];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_060', v_cust_id, v_batch_id, 7000.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 7000.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_060_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 61: evt_synth_061 (network_timeout, Rs 7150.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000061'::UUID;
    v_cust_id := v_cust_ids[2];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_061', v_cust_id, v_batch_id, 7150.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 7150.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_061_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 62: evt_synth_062 (network_timeout, Rs 7300.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000062'::UUID;
    v_cust_id := v_cust_ids[3];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_062', v_cust_id, v_batch_id, 7300.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 7300.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_062_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 63: evt_synth_063 (network_timeout, Rs 7450.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000063'::UUID;
    v_cust_id := v_cust_ids[4];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_063', v_cust_id, v_batch_id, 7450.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 7450.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_063_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 64: evt_synth_064 (network_timeout, Rs 7600.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000064'::UUID;
    v_cust_id := v_cust_ids[5];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_064', v_cust_id, v_batch_id, 7600.00, 'INR', 'UPI', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 7600.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_064_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_064_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 65: evt_synth_065 (network_timeout, Rs 7750.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000065'::UUID;
    v_cust_id := v_cust_ids[6];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_065', v_cust_id, v_batch_id, 7750.00, 'INR', 'NETBANKING', 'GATEWAY_TIMEOUT', 'Upstream bank connection timed out', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'network_timeout', 0.9400, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"network_timeout","confidence":0.94,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as network_timeout with confidence 0.94');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'network_timeout', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60', 7750.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for network_timeout with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_065_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_065_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 66: evt_synth_066 (bank_declined, Rs 3180.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000066'::UUID;
    v_cust_id := v_cust_ids[7];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_066', v_cust_id, v_batch_id, 3180.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 3180.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_066_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 67: evt_synth_067 (bank_declined, Rs 3360.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000067'::UUID;
    v_cust_id := v_cust_ids[8];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_067', v_cust_id, v_batch_id, 3360.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 3360.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_067_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 68: evt_synth_068 (bank_declined, Rs 3540.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000068'::UUID;
    v_cust_id := v_cust_ids[9];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_068', v_cust_id, v_batch_id, 3540.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 3540.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_068_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 69: evt_synth_069 (bank_declined, Rs 3720.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000069'::UUID;
    v_cust_id := v_cust_ids[10];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_069', v_cust_id, v_batch_id, 3720.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 3720.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_069_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 70: evt_synth_070 (bank_declined, Rs 3900.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000070'::UUID;
    v_cust_id := v_cust_ids[11];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_070', v_cust_id, v_batch_id, 3900.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 3900.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_070_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 71: evt_synth_071 (bank_declined, Rs 4080.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000071'::UUID;
    v_cust_id := v_cust_ids[12];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_071', v_cust_id, v_batch_id, 4080.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 4080.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_071_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 72: evt_synth_072 (bank_declined, Rs 4260.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000072'::UUID;
    v_cust_id := v_cust_ids[13];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_072', v_cust_id, v_batch_id, 4260.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 4260.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_072_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 73: evt_synth_073 (bank_declined, Rs 4440.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000073'::UUID;
    v_cust_id := v_cust_ids[14];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_073', v_cust_id, v_batch_id, 4440.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 4440.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_073_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 74: evt_synth_074 (bank_declined, Rs 4620.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000074'::UUID;
    v_cust_id := v_cust_ids[15];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_074', v_cust_id, v_batch_id, 4620.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 4620.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_074_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 75: evt_synth_075 (bank_declined, Rs 4800.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000075'::UUID;
    v_cust_id := v_cust_ids[16];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_075', v_cust_id, v_batch_id, 4800.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 4800.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_075_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 76: evt_synth_076 (bank_declined, Rs 4980.00, status: RECOVERED)
    v_event_id := 'e0000000-0000-0000-0000-000000000076'::UUID;
    v_cust_id := v_cust_ids[17];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_076', v_cust_id, v_batch_id, 4980.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'RECOVERED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 4980.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
    VALUES (v_event_id, 1, 'MOCK', 'SUCCESS', 'mock_txn_076_1');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Mock recovery successful on attempt 1');
    -- Event 77: evt_synth_077 (bank_declined, Rs 5160.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000077'::UUID;
    v_cust_id := v_cust_ids[18];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_077', v_cust_id, v_batch_id, 5160.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 5160.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_077_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_077_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 78: evt_synth_078 (bank_declined, Rs 5340.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000078'::UUID;
    v_cust_id := v_cust_ids[19];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_078', v_cust_id, v_batch_id, 5340.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 5340.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_078_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_078_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 79: evt_synth_079 (bank_declined, Rs 5520.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000079'::UUID;
    v_cust_id := v_cust_ids[20];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_079', v_cust_id, v_batch_id, 5520.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 5520.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_079_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_079_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 80: evt_synth_080 (bank_declined, Rs 5700.00, status: FAILED)
    v_event_id := 'e0000000-0000-0000-0000-000000000080'::UUID;
    v_cust_id := v_cust_ids[1];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_080', v_cust_id, v_batch_id, 5700.00, 'INR', 'CARD', 'BANK_DECLINED', 'Card issuing bank declined the transaction', 'FAILED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'bank_declined', 0.7900, 'RETRY', 'llama-3.3-70b-versatile', '{"reason_code":"bank_declined","confidence":0.79,"suggested_action":"RETRY"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as bank_declined with confidence 0.79');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'RETRY', 1, 'bank_declined', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60', 5700.00, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 allows autonomous retry for bank_declined with confidence >= 0.60');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 1, 'MOCK', 'FAILED', 'mock_txn_080_1', 'Payment decline repeated');
    INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id, error_message)
    VALUES (v_event_id, 2, 'MOCK', 'FAILED', 'mock_txn_080_2', 'Final retry attempt unsuccessful');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'RETRY_EXECUTED', 'Retries exhausted, marked failed');
    -- Event 81: evt_synth_081 (card_expired, Rs 2600.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000081'::UUID;
    v_cust_id := v_cust_ids[2];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_081', v_cust_id, v_batch_id, 2600.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_81@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 2600.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 82: evt_synth_082 (card_expired, Rs 2700.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000082'::UUID;
    v_cust_id := v_cust_ids[3];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_082', v_cust_id, v_batch_id, 2700.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_82@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 2700.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 83: evt_synth_083 (card_expired, Rs 2800.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000083'::UUID;
    v_cust_id := v_cust_ids[4];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_083', v_cust_id, v_batch_id, 2800.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_83@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 2800.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 84: evt_synth_084 (card_expired, Rs 2900.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000084'::UUID;
    v_cust_id := v_cust_ids[5];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_084', v_cust_id, v_batch_id, 2900.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_84@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 2900.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 85: evt_synth_085 (card_expired, Rs 3000.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000085'::UUID;
    v_cust_id := v_cust_ids[6];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_085', v_cust_id, v_batch_id, 3000.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_85@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 3000.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 86: evt_synth_086 (card_expired, Rs 3100.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000086'::UUID;
    v_cust_id := v_cust_ids[7];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_086', v_cust_id, v_batch_id, 3100.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_86@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 3100.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 87: evt_synth_087 (card_expired, Rs 3200.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000087'::UUID;
    v_cust_id := v_cust_ids[8];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_087', v_cust_id, v_batch_id, 3200.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_87@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 3200.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 88: evt_synth_088 (card_expired, Rs 3300.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000088'::UUID;
    v_cust_id := v_cust_ids[9];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_088', v_cust_id, v_batch_id, 3300.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_88@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 3300.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 89: evt_synth_089 (card_expired, Rs 3400.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000089'::UUID;
    v_cust_id := v_cust_ids[10];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_089', v_cust_id, v_batch_id, 3400.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_89@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 3400.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 90: evt_synth_090 (card_expired, Rs 3500.00, status: ACTIONED)
    v_event_id := 'e0000000-0000-0000-0000-000000000090'::UUID;
    v_cust_id := v_cust_ids[11];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_090', v_cust_id, v_batch_id, 3500.00, 'INR', 'CARD', 'CARD_EXPIRED', 'Credit card validity expired', 'ACTIONED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'card_expired', 0.9500, 'REQUEST_UPDATE', 'llama-3.3-70b-versatile', '{"reason_code":"card_expired","confidence":0.95,"suggested_action":"REQUEST_UPDATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as card_expired with confidence 0.95');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'REQUEST_UPDATE', 1, 'card_expired', 'Policy v1 specifies customer notification to request updated card details', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 specifies customer notification to request updated card details');
    INSERT INTO recovery_messages (payment_event_id, channel, recipient, subject, body, status)
    VALUES (v_event_id, 'EMAIL', 'customer_90@example.com', 'Action Required: Update Payment Method for RevGuard', 'Your payment of Rs 3500.00 could not be processed due to an expired card. Please click here to update your card.', 'DRAFTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'MESSAGE_DRAFTED', 'Customer update request email drafted');
    -- Event 91: evt_synth_091 (fraud_suspected, Rs 3800.00, status: BLOCKED)
    v_event_id := 'e0000000-0000-0000-0000-000000000091'::UUID;
    v_cust_id := v_cust_ids[12];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_091', v_cust_id, v_batch_id, 3800.00, 'INR', 'CARD', 'HIGH_RISK_DECLINE', 'Transaction blocked by fraud risk engine', 'BLOCKED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'fraud_suspected', 0.9200, 'BLOCK', 'llama-3.3-70b-versatile', '{"reason_code":"fraud_suspected","confidence":0.92,"suggested_action":"BLOCK"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as fraud_suspected with confidence 0.92');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'BLOCK', 1, 'fraud_suspected', 'Policy v1 strictly blocks any retry on suspected fraud', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 strictly blocks any retry on suspected fraud');
    -- Event 92: evt_synth_092 (fraud_suspected, Rs 4100.00, status: BLOCKED)
    v_event_id := 'e0000000-0000-0000-0000-000000000092'::UUID;
    v_cust_id := v_cust_ids[13];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_092', v_cust_id, v_batch_id, 4100.00, 'INR', 'CARD', 'HIGH_RISK_DECLINE', 'Transaction blocked by fraud risk engine', 'BLOCKED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'fraud_suspected', 0.9200, 'BLOCK', 'llama-3.3-70b-versatile', '{"reason_code":"fraud_suspected","confidence":0.92,"suggested_action":"BLOCK"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as fraud_suspected with confidence 0.92');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'BLOCK', 1, 'fraud_suspected', 'Policy v1 strictly blocks any retry on suspected fraud', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 strictly blocks any retry on suspected fraud');
    -- Event 93: evt_synth_093 (fraud_suspected, Rs 4400.00, status: BLOCKED)
    v_event_id := 'e0000000-0000-0000-0000-000000000093'::UUID;
    v_cust_id := v_cust_ids[14];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_093', v_cust_id, v_batch_id, 4400.00, 'INR', 'CARD', 'HIGH_RISK_DECLINE', 'Transaction blocked by fraud risk engine', 'BLOCKED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'fraud_suspected', 0.9200, 'BLOCK', 'llama-3.3-70b-versatile', '{"reason_code":"fraud_suspected","confidence":0.92,"suggested_action":"BLOCK"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as fraud_suspected with confidence 0.92');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'BLOCK', 1, 'fraud_suspected', 'Policy v1 strictly blocks any retry on suspected fraud', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 strictly blocks any retry on suspected fraud');
    -- Event 94: evt_synth_094 (fraud_suspected, Rs 4700.00, status: BLOCKED)
    v_event_id := 'e0000000-0000-0000-0000-000000000094'::UUID;
    v_cust_id := v_cust_ids[15];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_094', v_cust_id, v_batch_id, 4700.00, 'INR', 'CARD', 'HIGH_RISK_DECLINE', 'Transaction blocked by fraud risk engine', 'BLOCKED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'fraud_suspected', 0.9200, 'BLOCK', 'llama-3.3-70b-versatile', '{"reason_code":"fraud_suspected","confidence":0.92,"suggested_action":"BLOCK"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as fraud_suspected with confidence 0.92');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'BLOCK', 1, 'fraud_suspected', 'Policy v1 strictly blocks any retry on suspected fraud', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 strictly blocks any retry on suspected fraud');
    -- Event 95: evt_synth_095 (fraud_suspected, Rs 5000.00, status: BLOCKED)
    v_event_id := 'e0000000-0000-0000-0000-000000000095'::UUID;
    v_cust_id := v_cust_ids[16];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_095', v_cust_id, v_batch_id, 5000.00, 'INR', 'CARD', 'HIGH_RISK_DECLINE', 'Transaction blocked by fraud risk engine', 'BLOCKED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'fraud_suspected', 0.9200, 'BLOCK', 'llama-3.3-70b-versatile', '{"reason_code":"fraud_suspected","confidence":0.92,"suggested_action":"BLOCK"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as fraud_suspected with confidence 0.92');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'BLOCK', 1, 'fraud_suspected', 'Policy v1 strictly blocks any retry on suspected fraud', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Policy v1 strictly blocks any retry on suspected fraud');
    -- Event 96: evt_synth_096 (other, Rs 1700.00, status: ESCALATED)
    v_event_id := 'e0000000-0000-0000-0000-000000000096'::UUID;
    v_cust_id := v_cust_ids[17];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_096', v_cust_id, v_batch_id, 1700.00, 'INR', 'WALLET', 'UNKNOWN_ERROR', 'Generic processing failure', 'ESCALATED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'other', 0.3500, 'ESCALATE', 'llama-3.3-70b-versatile', '{"reason_code":"other","confidence":0.35,"suggested_action":"ESCALATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as other with confidence 0.35');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'ESCALATE', 1, 'other', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review');
    -- Event 97: evt_synth_097 (other, Rs 1900.00, status: ESCALATED)
    v_event_id := 'e0000000-0000-0000-0000-000000000097'::UUID;
    v_cust_id := v_cust_ids[18];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_097', v_cust_id, v_batch_id, 1900.00, 'INR', 'WALLET', 'UNKNOWN_ERROR', 'Generic processing failure', 'ESCALATED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'other', 0.3500, 'ESCALATE', 'llama-3.3-70b-versatile', '{"reason_code":"other","confidence":0.35,"suggested_action":"ESCALATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as other with confidence 0.35');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'ESCALATE', 1, 'other', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review');
    -- Event 98: evt_synth_098 (other, Rs 2100.00, status: ESCALATED)
    v_event_id := 'e0000000-0000-0000-0000-000000000098'::UUID;
    v_cust_id := v_cust_ids[19];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_098', v_cust_id, v_batch_id, 2100.00, 'INR', 'WALLET', 'UNKNOWN_ERROR', 'Generic processing failure', 'ESCALATED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'other', 0.3500, 'ESCALATE', 'llama-3.3-70b-versatile', '{"reason_code":"other","confidence":0.35,"suggested_action":"ESCALATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as other with confidence 0.35');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'ESCALATE', 1, 'other', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review');
    -- Event 99: evt_synth_099 (other, Rs 2300.00, status: ESCALATED)
    v_event_id := 'e0000000-0000-0000-0000-000000000099'::UUID;
    v_cust_id := v_cust_ids[20];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_099', v_cust_id, v_batch_id, 2300.00, 'INR', 'WALLET', 'UNKNOWN_ERROR', 'Generic processing failure', 'ESCALATED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'other', 0.3500, 'ESCALATE', 'llama-3.3-70b-versatile', '{"reason_code":"other","confidence":0.35,"suggested_action":"ESCALATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as other with confidence 0.35');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'ESCALATE', 1, 'other', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review');
    -- Event 100: evt_synth_100 (other, Rs 2500.00, status: ESCALATED)
    v_event_id := 'e0000000-0000-0000-0000-000000000100'::UUID;
    v_cust_id := v_cust_ids[1];
    INSERT INTO payment_events (id, event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
    VALUES (v_event_id, 'evt_synth_100', v_cust_id, v_batch_id, 2500.00, 'INR', 'WALLET', 'UNKNOWN_ERROR', 'Generic processing failure', 'ESCALATED');
    INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name, raw_response)
    VALUES (v_event_id, 'other', 0.3500, 'ESCALATE', 'llama-3.3-70b-versatile', '{"reason_code":"other","confidence":0.35,"suggested_action":"ESCALATE"}');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'SYSTEM', 'PAYMENT_INGESTED', 'Payment failure event received and validated');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'LLM', 'FAILURE_DIAGNOSED', 'Classified as other with confidence 0.35');
    INSERT INTO recovery_actions (payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
    VALUES (v_event_id, 'ESCALATE', 1, 'other', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review', NULL, 'EXECUTED');
    INSERT INTO audit_log (payment_event_id, actor, action, reason) VALUES (v_event_id, 'POLICY_ENGINE', 'ACTION_DECIDED', 'Confidence 0.35 is below minimum threshold 0.60; routing to human review');
END $$;
