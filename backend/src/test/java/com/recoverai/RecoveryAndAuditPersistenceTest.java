package com.recoverai;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
class RecoveryAndAuditPersistenceTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID customerId;
    private UUID eventId;

    @BeforeEach
    void setUp() {
        customerId = UUID.randomUUID();
        jdbcTemplate.update(
                "INSERT INTO customers (id, email, name) VALUES (?, ?, ?)",
                customerId, "merchant@example.com", "Merchant User"
        );

        eventId = UUID.randomUUID();
        String externalEventId = "evt_persist_" + System.currentTimeMillis();
        jdbcTemplate.update(
                """
                INSERT INTO payment_events (id, event_id, customer_id, amount, currency, status)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                eventId, externalEventId, customerId, new BigDecimal("4999.00"), "INR", "DIAGNOSED"
        );
    }

    @Test
    @DisplayName("Verify recovery_actions records decision reason and policy_version tracking")
    void testRecoveryActionsAndPolicyVersionTracking() {
        UUID actionId = UUID.randomUUID();
        jdbcTemplate.update(
                """
                INSERT INTO recovery_actions (id, payment_event_id, action_type, policy_version, policy_reason_code, decision_reason, authorized_amount, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                actionId, eventId, "RETRY", 1, "insufficient_funds", "Confidence 0.92 >= 0.60 threshold and amount <= 20000", new BigDecimal("4999.00"), "PENDING"
        );

        Map<String, Object> action = jdbcTemplate.queryForMap(
                "SELECT * FROM recovery_actions WHERE id = ?", actionId
        );

        assertThat(action.get("action_type")).isEqualTo("RETRY");
        assertThat(((Number) action.get("policy_version")).intValue()).isEqualTo(1);
        assertThat(action.get("policy_reason_code")).isEqualTo("insufficient_funds");
        assertThat((String) action.get("decision_reason")).contains("Confidence 0.92 >= 0.60");
    }

    @Test
    @DisplayName("Verify retry_attempts records executor outcomes and enforces unique(event, attempt_number)")
    void testRetryAttemptsUniqueConstraint() {
        // Attempt 1 succeeds
        jdbcTemplate.update(
                """
                INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
                VALUES (?, ?, ?, ?, ?)
                """,
                eventId, 1, "MOCK", "FAILED", "mock_txn_001"
        );

        // Attempt 2 succeeds
        jdbcTemplate.update(
                """
                INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
                VALUES (?, ?, ?, ?, ?)
                """,
                eventId, 2, "MOCK", "SUCCESS", "mock_txn_002"
        );

        int count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM retry_attempts WHERE payment_event_id = ?",
                Integer.class,
                eventId
        );
        assertThat(count).isEqualTo(2);

        // Duplicate Attempt 1 for same payment_event must throw DataIntegrityViolationException
        assertThatThrownBy(() -> jdbcTemplate.update(
                """
                INSERT INTO retry_attempts (payment_event_id, attempt_number, executor_type, status, gateway_reference_id)
                VALUES (?, ?, ?, ?, ?)
                """,
                eventId, 1, "RAZORPAY", "FAILED", "rzp_dup_001"
        )).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Verify recovery_messages draft status and status check constraint")
    void testRecoveryMessagesStatusConstraint() {
        UUID messageId = UUID.randomUUID();
        jdbcTemplate.update(
                """
                INSERT INTO recovery_messages (id, payment_event_id, channel, recipient, subject, body, status)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                messageId, eventId, "EMAIL", "merchant@example.com", "Action Required: Payment Update", "Please update your payment card.", "DRAFTED"
        );

        Map<String, Object> message = jdbcTemplate.queryForMap(
                "SELECT * FROM recovery_messages WHERE id = ?", messageId
        );
        assertThat(message.get("status")).isEqualTo("DRAFTED");

        // Invalid status should violate check constraint
        assertThatThrownBy(() -> jdbcTemplate.update(
                """
                INSERT INTO recovery_messages (payment_event_id, channel, recipient, body, status)
                VALUES (?, ?, ?, ?, ?)
                """,
                eventId, "EMAIL", "merchant@example.com", "Body", "INVALID_STATUS"
        )).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Verify audit_log records actor, action, reason, and validates actor enum check")
    void testAuditLogActorAndReason() {
        UUID auditId = UUID.randomUUID();
        jdbcTemplate.update(
                """
                INSERT INTO audit_log (id, payment_event_id, actor, action, reason)
                VALUES (?, ?, ?, ?, ?)
                """,
                auditId, eventId, "POLICY_ENGINE", "RETRY_AUTHORIZED", "Evaluated policy v1: insufficient_funds under amount cap Rs20,000"
        );

        Map<String, Object> log = jdbcTemplate.queryForMap(
                "SELECT * FROM audit_log WHERE id = ?", auditId
        );
        assertThat(log.get("actor")).isEqualTo("POLICY_ENGINE");
        assertThat(log.get("action")).isEqualTo("RETRY_AUTHORIZED");
        assertThat(log.get("reason")).toString().contains("Evaluated policy v1");

        // Invalid actor must violate check constraint
        assertThatThrownBy(() -> jdbcTemplate.update(
                """
                INSERT INTO audit_log (payment_event_id, actor, action, reason)
                VALUES (?, ?, ?, ?)
                """,
                eventId, "UNAUTHORIZED_BOT", "ACTION", "Test invalid actor"
        )).isInstanceOf(DataIntegrityViolationException.class);
    }
}
