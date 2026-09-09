package com.recoverai;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class DatabaseSchemaAndSeedVerificationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Verify all 5 Flyway migrations executed successfully")
    void testFlywayMigrations() {
        List<Map<String, Object>> migrations = jdbcTemplate.queryForList(
                "SELECT version, description, success FROM flyway_schema_history WHERE version IS NOT NULL ORDER BY installed_rank"
        );

        assertThat(migrations).hasSize(5);

        assertThat(migrations.get(0).get("version")).isEqualTo("1");
        assertThat(migrations.get(0).get("description")).isEqualTo("init foundation");
        assertThat((Boolean) migrations.get(0).get("success")).isTrue();

        assertThat(migrations.get(1).get("version")).isEqualTo("2");
        assertThat(migrations.get(1).get("description")).isEqualTo("core business tables");
        assertThat((Boolean) migrations.get(1).get("success")).isTrue();

        assertThat(migrations.get(2).get("version")).isEqualTo("3");
        assertThat(migrations.get(2).get("description")).isEqualTo("classification and policy model");
        assertThat((Boolean) migrations.get(2).get("success")).isTrue();

        assertThat(migrations.get(3).get("version")).isEqualTo("4");
        assertThat(migrations.get(3).get("description")).isEqualTo("recovery and audit persistence");
        assertThat((Boolean) migrations.get(3).get("success")).isTrue();

        assertThat(migrations.get(4).get("version")).isEqualTo("5");
        assertThat(migrations.get(4).get("description")).isEqualTo("seed synthetic recovery batch");
        assertThat((Boolean) migrations.get(4).get("success")).isTrue();
    }

    @Test
    @DisplayName("Verify all 9 domain tables exist in PostgreSQL public schema")
    void testAllTablesExist() {
        List<String> tableNames = jdbcTemplate.queryForList(
                """
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                """,
                String.class
        );

        assertThat(tableNames).contains(
                "customers",
                "recovery_batches",
                "payment_events",
                "classifications",
                "recovery_policies",
                "recovery_actions",
                "retry_attempts",
                "recovery_messages",
                "audit_log"
        );
    }

    @Test
    @DisplayName("Verify all required unique constraints exist in the schema")
    void testUniqueConstraintsExist() {
        List<String> constraints = jdbcTemplate.queryForList(
                """
                SELECT conname
                FROM pg_constraint con
                JOIN pg_class rel ON rel.oid = con.conrelid
                JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
                WHERE nsp.nspname = 'public' AND con.contype = 'u'
                """,
                String.class
        );

        // Core constraints mandated by Master Prompt
        assertThat(constraints).contains(
                "uk_payment_events_event_id",
                "uk_classifications_payment_event_id",
                "uk_recovery_policies_reason_version",
                "uk_retry_attempts_event_attempt"
        );
    }

    @Test
    @DisplayName("Verify foreign key constraints link all child tables to payment_events")
    void testForeignKeyConstraints() {
        List<String> foreignKeys = jdbcTemplate.queryForList(
                """
                SELECT conname
                FROM pg_constraint con
                JOIN pg_class rel ON rel.oid = con.conrelid
                JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
                WHERE nsp.nspname = 'public' AND con.contype = 'f'
                """,
                String.class
        );

        assertThat(foreignKeys).contains(
                "payment_events_customer_id_fkey",
                "payment_events_batch_id_fkey",
                "classifications_payment_event_id_fkey",
                "recovery_actions_payment_event_id_fkey",
                "retry_attempts_payment_event_id_fkey",
                "recovery_messages_payment_event_id_fkey",
                "audit_log_payment_event_id_fkey"
        );
    }

    @Test
    @DisplayName("Verify intervention matrix policy rules and policy version tracking")
    void testPolicyRulesAndVersioning() {
        Integer activeCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recovery_policies WHERE active = true",
                Integer.class
        );
        assertThat(activeCount).isEqualTo(6);

        // Check recovery_actions has policy_version tracking column
        List<String> actionCols = jdbcTemplate.queryForList(
                """
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'recovery_actions'
                """,
                String.class
        );
        assertThat(actionCols).contains("policy_version", "policy_reason_code", "decision_reason", "authorized_amount");

        // Verify seeded actions reference policy_version 1
        Integer actionsWithVersion1 = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recovery_actions WHERE policy_version = 1",
                Integer.class
        );
        assertThat(actionsWithVersion1).isGreaterThanOrEqualTo(100);
    }

    @Test
    @DisplayName("Verify synthetic batch end-to-end data integrity and 65-75% money-weighted recovery rate")
    void testSyntheticDataIntegrity() {
        Map<String, Object> batch = jdbcTemplate.queryForMap(
                "SELECT total_events, at_risk_amount, recovered_amount, recovery_rate FROM recovery_batches WHERE batch_name = 'BATCH-2026-SYNTH-01'"
        );

        assertThat(((Number) batch.get("total_events")).intValue()).isEqualTo(100);

        BigDecimal atRisk = (BigDecimal) batch.get("at_risk_amount");
        BigDecimal recovered = (BigDecimal) batch.get("recovered_amount");
        BigDecimal recoveryRate = (BigDecimal) batch.get("recovery_rate");

        assertThat(atRisk).isEqualByComparingTo("511870.00");
        assertThat(recovered).isEqualByComparingTo("353640.00");
        assertThat(recoveryRate).isEqualByComparingTo("69.09");

        // Double check money-weighted calculation rule
        BigDecimal manualCalculation = recovered.multiply(BigDecimal.valueOf(100)).divide(atRisk, 2, java.math.RoundingMode.HALF_UP);
        assertThat(manualCalculation).isEqualByComparingTo("69.09");
        assertThat(manualCalculation.doubleValue()).isBetween(65.0, 75.0);

        // Events count per customer
        Integer customerCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT customer_id) FROM payment_events",
                Integer.class
        );
        assertThat(customerCount).isEqualTo(20);
    }
}
