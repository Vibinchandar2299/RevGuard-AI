package com.recoverai;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class SyntheticRecoveryBatchDataTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Verify synthetic recovery batch metrics and money-weighted recovery rate")
    void testSyntheticRecoveryBatchMetrics() {
        UUID batchId = UUID.fromString("b0000000-0000-0000-0000-000000000001");

        // 1. Verify Batch row
        Map<String, Object> batch = jdbcTemplate.queryForMap(
                "SELECT * FROM recovery_batches WHERE id = ?", batchId
        );

        assertThat(batch).isNotNull();
        assertThat(batch.get("batch_name")).isEqualTo("BATCH-2026-SYNTH-01");
        assertThat(batch.get("status")).isEqualTo("COMPLETED");
        assertThat(((Number) batch.get("total_events")).intValue()).isEqualTo(100);

        BigDecimal atRiskAmount = (BigDecimal) batch.get("at_risk_amount");
        BigDecimal recoveredAmount = (BigDecimal) batch.get("recovered_amount");
        BigDecimal recoveryRate = (BigDecimal) batch.get("recovery_rate");

        assertThat(atRiskAmount).isEqualByComparingTo("511870.00");
        assertThat(recoveredAmount).isEqualByComparingTo("353640.00");
        assertThat(recoveryRate).isEqualByComparingTo("69.09");

        // Calculate money-weighted recovery rate directly from DB
        BigDecimal calculatedRate = recoveredAmount
                .divide(atRiskAmount, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, RoundingMode.HALF_UP);

        assertThat(calculatedRate).isEqualByComparingTo("69.09");
        assertThat(calculatedRate.doubleValue()).isBetween(65.0, 75.0);

        // 2. Verify Reason Code Distribution
        List<Map<String, Object>> reasonCounts = jdbcTemplate.queryForList(
                """
                SELECT c.reason_code, COUNT(*) as cnt, SUM(pe.amount) as total_amt
                FROM payment_events pe
                JOIN classifications c ON pe.id = c.payment_event_id
                WHERE pe.batch_id = ?
                GROUP BY c.reason_code
                ORDER BY cnt DESC
                """,
                batchId
        );

        Map<String, Integer> countByReason = reasonCounts.stream()
                .collect(java.util.stream.Collectors.toMap(
                        m -> (String) m.get("reason_code"),
                        m -> ((Number) m.get("cnt")).intValue()
                ));

        assertThat(countByReason.get("insufficient_funds")).isEqualTo(40);
        assertThat(countByReason.get("network_timeout")).isEqualTo(25);
        assertThat(countByReason.get("bank_declined")).isEqualTo(15);
        assertThat(countByReason.get("card_expired")).isEqualTo(10);
        assertThat(countByReason.get("fraud_suspected")).isEqualTo(5);
        assertThat(countByReason.get("other")).isEqualTo(5);

        // 3. Verify Payment Events Status Distribution
        int recoveredEventsCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM payment_events WHERE batch_id = ? AND status = 'RECOVERED'",
                Integer.class, batchId
        );
        assertThat(recoveredEventsCount).isEqualTo(66);

        // Verify that sum of recovered event amounts equals batch recovered_amount
        BigDecimal sumRecoveredAmounts = jdbcTemplate.queryForObject(
                "SELECT SUM(amount) FROM payment_events WHERE batch_id = ? AND status = 'RECOVERED'",
                BigDecimal.class, batchId
        );
        assertThat(sumRecoveredAmounts).isEqualByComparingTo("353640.00");

        // 4. Verify Associated Records
        int classificationCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM classifications c JOIN payment_events pe ON c.payment_event_id = pe.id WHERE pe.batch_id = ?",
                Integer.class, batchId
        );
        assertThat(classificationCount).isEqualTo(100);

        int actionCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recovery_actions ra JOIN payment_events pe ON ra.payment_event_id = pe.id WHERE pe.batch_id = ?",
                Integer.class, batchId
        );
        assertThat(actionCount).isEqualTo(100);

        int messageCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recovery_messages rm JOIN payment_events pe ON rm.payment_event_id = pe.id WHERE pe.batch_id = ?",
                Integer.class, batchId
        );
        assertThat(messageCount).isEqualTo(10); // 10 card_expired events drafted

        int auditLogCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM audit_log al JOIN payment_events pe ON al.payment_event_id = pe.id WHERE pe.batch_id = ?",
                Integer.class, batchId
        );
        assertThat(auditLogCount).isGreaterThanOrEqualTo(300); // INGESTED, DIAGNOSED, ACTIONED, RETRIED/DRAFTED
    }
}
