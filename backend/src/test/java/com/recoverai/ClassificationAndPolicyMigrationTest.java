package com.recoverai;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
class ClassificationAndPolicyMigrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Verify active versioned recovery policies seeded from intervention matrix")
    void testActiveVersionedPoliciesSeeded() {
        // Query active policies
        List<Map<String, Object>> activePolicies = jdbcTemplate.queryForList(
                "SELECT reason_code, version, active, min_confidence, action, max_attempts, cooldown_seconds, amount_cap FROM recovery_policies WHERE active = true ORDER BY reason_code"
        );

        assertThat(activePolicies).hasSize(6);

        Map<String, Map<String, Object>> policyMap = activePolicies.stream()
                .collect(java.util.stream.Collectors.toMap(
                        m -> (String) m.get("reason_code"),
                        m -> m
                ));

        // 1. insufficient_funds: min_confidence 0.6, action RETRY, max_attempts 3, cooldown 60s, amount_cap 20000.00
        Map<String, Object> insufficientFunds = policyMap.get("insufficient_funds");
        assertThat(insufficientFunds).isNotNull();
        assertThat(((Number) insufficientFunds.get("version")).intValue()).isEqualTo(1);
        assertThat(((Number) insufficientFunds.get("min_confidence")).doubleValue()).isEqualTo(0.6);
        assertThat(insufficientFunds.get("action")).isEqualTo("RETRY");
        assertThat(((Number) insufficientFunds.get("max_attempts")).intValue()).isEqualTo(3);
        assertThat(((Number) insufficientFunds.get("cooldown_seconds")).intValue()).isEqualTo(60);
        assertThat(((BigDecimal) insufficientFunds.get("amount_cap"))).isEqualByComparingTo("20000.00");

        // 2. network_timeout: min_confidence 0.6, action RETRY, max_attempts 3, cooldown 20s
        Map<String, Object> networkTimeout = policyMap.get("network_timeout");
        assertThat(networkTimeout).isNotNull();
        assertThat(((Number) networkTimeout.get("min_confidence")).doubleValue()).isEqualTo(0.6);
        assertThat(networkTimeout.get("action")).isEqualTo("RETRY");
        assertThat(((Number) networkTimeout.get("max_attempts")).intValue()).isEqualTo(3);
        assertThat(((Number) networkTimeout.get("cooldown_seconds")).intValue()).isEqualTo(20);

        // 3. bank_declined: min_confidence 0.6, action RETRY, max_attempts 2, cooldown 90s
        Map<String, Object> bankDeclined = policyMap.get("bank_declined");
        assertThat(bankDeclined).isNotNull();
        assertThat(((Number) bankDeclined.get("min_confidence")).doubleValue()).isEqualTo(0.6);
        assertThat(bankDeclined.get("action")).isEqualTo("RETRY");
        assertThat(((Number) bankDeclined.get("max_attempts")).intValue()).isEqualTo(2);
        assertThat(((Number) bankDeclined.get("cooldown_seconds")).intValue()).isEqualTo(90);

        // 4. card_expired: action REQUEST_UPDATE, max_attempts 0
        Map<String, Object> cardExpired = policyMap.get("card_expired");
        assertThat(cardExpired).isNotNull();
        assertThat(cardExpired.get("action")).isEqualTo("REQUEST_UPDATE");
        assertThat(((Number) cardExpired.get("max_attempts")).intValue()).isEqualTo(0);

        // 5. fraud_suspected: action BLOCK, max_attempts 0
        Map<String, Object> fraudSuspected = policyMap.get("fraud_suspected");
        assertThat(fraudSuspected).isNotNull();
        assertThat(fraudSuspected.get("action")).isEqualTo("BLOCK");
        assertThat(((Number) fraudSuspected.get("max_attempts")).intValue()).isEqualTo(0);

        // 6. other: action ESCALATE, max_attempts 0
        Map<String, Object> other = policyMap.get("other");
        assertThat(other).isNotNull();
        assertThat(other.get("action")).isEqualTo("ESCALATE");
        assertThat(((Number) other.get("max_attempts")).intValue()).isEqualTo(0);
    }

    @Test
    @DisplayName("Verify unique(reason_code, version) constraint on duplicate insert")
    void testPolicyDuplicateConstraintViolated() {
        // Attempting duplicate (insufficient_funds, version 1) must violate unique constraint
        assertThatThrownBy(() -> jdbcTemplate.update(
                """
                INSERT INTO recovery_policies (reason_code, version, active, min_confidence, action, max_attempts)
                VALUES ('insufficient_funds', 1, false, 0.60, 'RETRY', 3)
                """
        )).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Verify policy versioning supports adding new policy version")
    void testPolicyNewVersionInsertion() {
        // Version 2 of insufficient_funds succeeds
        int inserted = jdbcTemplate.update(
                """
                INSERT INTO recovery_policies (reason_code, version, active, min_confidence, action, max_attempts, cooldown_seconds, amount_cap, escalate_after_attempts)
                VALUES ('insufficient_funds', 2, false, 0.70, 'RETRY', 2, 120, 15000.00, 2)
                """
        );
        assertThat(inserted).isEqualTo(1);
    }

    @Test
    @DisplayName("Verify at-most-one classification per payment_event constraint")
    void testAtMostOneClassificationConstraint() {
        // Insert customer
        UUID customerId = UUID.randomUUID();
        jdbcTemplate.update(
                "INSERT INTO customers (id, email, name) VALUES (?, ?, ?)",
                customerId, "customer2@example.com", "Test Customer"
        );

        // Insert payment event
        UUID eventId = UUID.randomUUID();
        String externalEventId = "evt_clf_" + System.currentTimeMillis();
        jdbcTemplate.update(
                """
                INSERT INTO payment_events (id, event_id, customer_id, amount, currency, status)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                eventId, externalEventId, customerId, new BigDecimal("2500.00"), "INR", "INGESTED"
        );

        // Insert first classification (success)
        jdbcTemplate.update(
                """
                INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name)
                VALUES (?, ?, ?, ?, ?)
                """,
                eventId, "insufficient_funds", 0.9500, "RETRY", "llama-3.3-70b-versatile"
        );

        // Insert second classification for SAME payment_event_id: MUST throw DataIntegrityViolationException
        assertThatThrownBy(() -> jdbcTemplate.update(
                """
                INSERT INTO classifications (payment_event_id, reason_code, confidence, suggested_action, model_name)
                VALUES (?, ?, ?, ?, ?)
                """,
                eventId, "bank_declined", 0.8500, "RETRY", "llama-3.3-70b-versatile"
        )).isInstanceOf(DataIntegrityViolationException.class);
    }
}
