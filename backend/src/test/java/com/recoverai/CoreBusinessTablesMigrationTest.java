package com.recoverai;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
class CoreBusinessTablesMigrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Verify tables exist, FKs work, and UNIQUE(event_id) idempotency constraint is enforced")
    void testCoreTablesAndIdempotencyConstraint() {
        // 1. Insert customer
        UUID customerId = UUID.randomUUID();
        jdbcTemplate.update(
                "INSERT INTO customers (id, external_customer_id, email, name, phone) VALUES (?, ?, ?, ?, ?)",
                customerId, "CUST-001", "alex@example.com", "Alex Merchant", "+919876543210"
        );

        // 2. Insert recovery batch
        UUID batchId = UUID.randomUUID();
        jdbcTemplate.update(
                "INSERT INTO recovery_batches (id, batch_name, status, total_events, at_risk_amount) VALUES (?, ?, ?, ?, ?)",
                batchId, "BATCH-TEST-01", "PENDING", 1, new BigDecimal("1500.00")
        );

        // 3. Insert payment event
        String eventId = "evt_test_" + System.currentTimeMillis();
        jdbcTemplate.update(
                """
                INSERT INTO payment_events (event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                eventId, customerId, batchId, new BigDecimal("1500.00"), "INR", "CARD", "insufficient_funds", "Account balance low", "INGESTED"
        );

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM payment_events WHERE event_id = ?",
                Integer.class,
                eventId
        );
        assertThat(count).isEqualTo(1);

        // 4. Assert UNIQUE(event_id) idempotency constraint: duplicate insert must throw DataIntegrityViolationException
        assertThatThrownBy(() -> jdbcTemplate.update(
                """
                INSERT INTO payment_events (event_id, customer_id, batch_id, amount, currency, payment_method, raw_failure_code, raw_failure_message, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                eventId, customerId, batchId, new BigDecimal("1500.00"), "INR", "CARD", "insufficient_funds", "Duplicate attempt", "INGESTED"
        )).isInstanceOf(DataIntegrityViolationException.class);
    }
}
