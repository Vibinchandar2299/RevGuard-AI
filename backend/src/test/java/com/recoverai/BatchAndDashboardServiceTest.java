package com.recoverai;

import com.recoverai.dto.*;
import com.recoverai.entity.*;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.*;
import com.recoverai.service.BatchService;
import com.recoverai.service.DashboardService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class BatchAndDashboardServiceTest {

    @Autowired
    private BatchService batchService;

    @Autowired
    private DashboardService dashboardService;

    @Autowired
    private RecoveryBatchRepository batchRepository;

    @Autowired
    private PaymentEventRepository paymentEventRepository;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @AfterEach
    void tearDown() {
        jdbcTemplate.update("DELETE FROM retry_attempts WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_batch_%')");
        jdbcTemplate.update("DELETE FROM recovery_actions WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_batch_%')");
        jdbcTemplate.update("DELETE FROM classifications WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_batch_%')");
        jdbcTemplate.update("DELETE FROM audit_log WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_batch_%')");
        jdbcTemplate.update("DELETE FROM payment_events WHERE event_id LIKE 'evt_batch_%'");
        jdbcTemplate.update("DELETE FROM recovery_batches WHERE batch_name LIKE 'BATCH-TEST-%'");
        jdbcTemplate.update("DELETE FROM customers WHERE email LIKE 'batch_test_%'");
    }

    @Test
    @DisplayName("Stage 5: Batch funnel metrics correctly compute money-weighted recovery rate for synthetic batch")
    void testCalculateFunnelMetrics_MatchesSyntheticBatch() {
        RecoveryBatch syntheticBatch = batchRepository.findByBatchName("BATCH-2026-SYNTH-01").orElseThrow();

        BatchFunnelMetrics funnel = batchService.calculateFunnelMetrics(syntheticBatch.getId());

        assertThat(funnel.getTotalEvents()).isEqualTo(100);
        assertThat(funnel.getAtRiskAmount()).isEqualByComparingTo(new BigDecimal("511870.00"));
        assertThat(funnel.getRecoveredAmount()).isEqualByComparingTo(new BigDecimal("353640.00"));
        assertThat(funnel.getRecoveryRate()).isEqualByComparingTo(new BigDecimal("69.09"));

        // Validate funnel steps
        assertThat(funnel.getDiagnosedEvents()).isEqualTo(100);
        assertThat(funnel.getPolicyApprovedEvents()).isGreaterThan(0);
        assertThat(funnel.getRetryExecutedEvents()).isGreaterThan(0);
        assertThat(funnel.getRecoveredEvents()).isGreaterThan(0);
        assertThat(funnel.getFailedEvents()).isGreaterThan(0);
    }

    @Test
    @DisplayName("Stage 5: Recalculate batch correctly updates RecoveryBatch entity fields")
    void testRecalculateBatch_UpdatesBatchEntity() {
        RecoveryBatch syntheticBatch = batchRepository.findByBatchName("BATCH-2026-SYNTH-01").orElseThrow();

        RecoveryBatch updated = batchService.recalculateAndSaveBatch(syntheticBatch.getId());

        assertThat(updated.getTotalEvents()).isEqualTo(100);
        assertThat(updated.getAtRiskAmount()).isEqualByComparingTo(new BigDecimal("511870.00"));
        assertThat(updated.getRecoveredAmount()).isEqualByComparingTo(new BigDecimal("353640.00"));
        assertThat(updated.getRecoveryRate()).isEqualByComparingTo(new BigDecimal("69.09"));
    }

    @Test
    @DisplayName("Stage 5: Run recovery pipeline for new batch processes policy decisions and retries")
    void testRunRecoveryPipeline_NewBatch() {
        Customer cust = customerRepository.save(Customer.builder()
                .name("Batch Run Test Customer")
                .email("batch_test_" + UUID.randomUUID() + "@example.com")
                .build());

        PaymentEvent event1 = paymentEventRepository.save(PaymentEvent.builder()
                .eventId("evt_batch_1_" + UUID.randomUUID())
                .customer(cust)
                .amount(new BigDecimal("3000.00"))
                .currency("INR")
                .paymentMethod("CARD")
                .rawFailureCode("network_timeout")
                .rawFailureMessage("Timeout")
                .status(PaymentStatus.INGESTED.name())
                .build());

        PaymentEvent event2 = paymentEventRepository.save(PaymentEvent.builder()
                .eventId("evt_batch_2_" + UUID.randomUUID())
                .customer(cust)
                .amount(new BigDecimal("5000.00"))
                .currency("INR")
                .paymentMethod("CARD")
                .rawFailureCode("card_expired")
                .rawFailureMessage("Card expired")
                .status(PaymentStatus.INGESTED.name())
                .build());

        BatchRunRequest req = BatchRunRequest.builder()
                .batchName("BATCH-TEST-" + UUID.randomUUID())
                .eventIds(List.of(event1.getEventId(), event2.getEventId()))
                .executeRetries(true)
                .build();

        BatchResponse response = batchService.runRecoveryPipeline(req);

        assertThat(response.getStatus()).isEqualTo("COMPLETED");
        assertThat(response.getTotalEvents()).isEqualTo(2);
        assertThat(response.getAtRiskAmount()).isEqualByComparingTo(new BigDecimal("8000.00"));
        assertThat(response.getFunnelMetrics()).isNotNull();

        // Event 1 (network timeout) should have recovered (Rs 3000)
        // Event 2 (card expired) should have zero retries (Rs 0 recovered)
        // Expected recovery rate: 3000 / 8000 * 100 = 37.50%
        assertThat(response.getRecoveredAmount()).isEqualByComparingTo(new BigDecimal("3000.00"));
        assertThat(response.getRecoveryRate()).isEqualByComparingTo(new BigDecimal("37.50"));
    }

    @Test
    @DisplayName("DashboardService: Summary aggregates across all events with correct recovery metrics")
    void testGetDashboardSummary() {
        DashboardSummaryResponse summary = dashboardService.getDashboardSummary();

        assertThat(summary.getTotalEvents()).isGreaterThanOrEqualTo(100);
        assertThat(summary.getTotalAtRiskAmount()).isGreaterThanOrEqualTo(new BigDecimal("511870.00"));
        assertThat(summary.getTotalRecoveredAmount()).isGreaterThanOrEqualTo(new BigDecimal("353640.00"));
        assertThat(summary.getAggregateRecoveryRate()).isGreaterThan(BigDecimal.ZERO);
        assertThat(summary.getActivePoliciesCount()).isEqualTo(6);
    }

    @Test
    @DisplayName("DashboardService: Reason breakdown groups volume and recovery rates accurately")
    void testGetReasonBreakdown() {
        List<ReasonBreakdownResponse> breakdown = dashboardService.getReasonBreakdown();

        assertThat(breakdown).isNotEmpty();
        assertThat(breakdown).anyMatch(r -> "insufficient_funds".equals(r.getReasonCode()) && r.getCount() > 0);
        assertThat(breakdown).anyMatch(r -> "network_timeout".equals(r.getReasonCode()) && r.getCount() > 0);
        assertThat(breakdown).anyMatch(r -> "bank_declined".equals(r.getReasonCode()) && r.getCount() > 0);
        assertThat(breakdown).anyMatch(r -> "card_expired".equals(r.getReasonCode()) && r.getCount() > 0);
        assertThat(breakdown).anyMatch(r -> "fraud_suspected".equals(r.getReasonCode()) && r.getCount() > 0);

        // Card expired and fraud suspected must have 0 recovered amount
        breakdown.stream()
                .filter(r -> "card_expired".equals(r.getReasonCode()) || "fraud_suspected".equals(r.getReasonCode()))
                .forEach(r -> assertThat(r.getRecoveredAmount()).isEqualByComparingTo(BigDecimal.ZERO));
    }

    @Test
    @DisplayName("DashboardService: Audit feed returns chronological timeline with actors and actions")
    void testGetRecentAuditFeed() {
        List<AuditFeedItemResponse> feed = dashboardService.getRecentAuditFeed(20);

        assertThat(feed).isNotEmpty();
        assertThat(feed.size()).isLessThanOrEqualTo(20);
        assertThat(feed.get(0).getActor()).isNotNull();
        assertThat(feed.get(0).getAction()).isNotNull();
        assertThat(feed.get(0).getCreatedAt()).isNotNull();
    }
}
