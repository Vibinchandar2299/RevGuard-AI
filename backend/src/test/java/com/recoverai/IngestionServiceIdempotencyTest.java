package com.recoverai;

import com.recoverai.dto.IngestionResponse;
import com.recoverai.dto.PaymentIngestionRequest;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.repository.AuditLogRepository;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.service.IngestionService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.math.BigDecimal;
import java.util.UUID;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class IngestionServiceIdempotencyTest {

    @Autowired
    private IngestionService ingestionService;

    @Autowired
    private PaymentEventRepository paymentEventRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @org.junit.jupiter.api.AfterEach
    void tearDown() {
        jdbcTemplate.update("DELETE FROM audit_log WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_idemp_%' OR event_id LIKE 'evt_race_%')");
        jdbcTemplate.update("DELETE FROM payment_events WHERE event_id LIKE 'evt_idemp_%' OR event_id LIKE 'evt_race_%'");
        jdbcTemplate.update("DELETE FROM customers WHERE email IN ('anand@example.com', 'race@example.com')");
    }

    @Test
    @DisplayName("Verify first ingestion succeeds and duplicate ingestion returns ALREADY_PROCESSED without side effects")
    void testIdempotentIngestion() {
        String eventId = "evt_idemp_" + UUID.randomUUID();

        PaymentIngestionRequest request = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("3500.00"))
                .currency("INR")
                .customerEmail("anand@example.com")
                .customerName("Anand Kumar")
                .paymentMethod("CARD")
                .rawFailureCode("ERR_INSUFFICIENT_FUNDS")
                .rawFailureMessage("Insufficient balance in card account")
                .build();

        // First Ingestion: Must succeed as new event
        IngestionResponse response1 = ingestionService.ingestEvent(request);
        assertThat(response1).isNotNull();
        assertThat(response1.getEventId()).isEqualTo(eventId);
        assertThat(response1.getStatus()).isEqualTo("INGESTED");
        assertThat(response1.isDuplicate()).isFalse();

        PaymentEvent saved = paymentEventRepository.findByEventId(eventId).orElse(null);
        assertThat(saved).isNotNull();
        assertThat(saved.getAmount()).isEqualByComparingTo("3500.00");

        int auditCountAfterFirst = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(saved.getId()).size();
        assertThat(auditCountAfterFirst).isEqualTo(1); // SYSTEM: PAYMENT_INGESTED

        // Second Ingestion: Exact same event_id must be detected as duplicate
        IngestionResponse response2 = ingestionService.ingestEvent(request);
        assertThat(response2).isNotNull();
        assertThat(response2.getEventId()).isEqualTo(eventId);
        assertThat(response2.getPaymentEventId()).isEqualTo(saved.getId());
        assertThat(response2.getStatus()).isEqualTo("ALREADY_PROCESSED");
        assertThat(response2.isDuplicate()).isTrue();
        assertThat(response2.getMessage()).contains("already processed");

        // Verify no duplicate records created in DB
        int eventCountInDb = paymentEventRepository.findAll().stream()
                .filter(e -> e.getEventId().equals(eventId))
                .toList().size();
        assertThat(eventCountInDb).isEqualTo(1);

        // Verify no duplicate side effects in audit log
        int auditCountAfterSecond = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(saved.getId()).size();
        assertThat(auditCountAfterSecond).isEqualTo(1);
    }

    @Test
    @DisplayName("Verify concurrent duplicate submissions safely deduplicate via database unique constraint")
    void testConcurrentDuplicateIngestion() throws Exception {
        String eventId = "evt_race_" + UUID.randomUUID();

        PaymentIngestionRequest request = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("1200.00"))
                .customerEmail("race@example.com")
                .customerName("Race Condition User")
                .paymentMethod("UPI")
                .rawFailureCode("NETWORK_TIMEOUT")
                .build();

        int threads = 4;
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch finishLatch = new CountDownLatch(threads);
        ConcurrentLinkedQueue<IngestionResponse> responses = new ConcurrentLinkedQueue<>();

        for (int i = 0; i < threads; i++) {
            executor.submit(() -> {
                try {
                    startLatch.await();
                    IngestionResponse res = ingestionService.ingestEvent(request);
                    responses.add(res);
                } catch (Exception e) {
                    // unexpected exception
                } finally {
                    finishLatch.countDown();
                }
            });
        }

        // Fire all threads simultaneously
        startLatch.countDown();
        finishLatch.await(5, TimeUnit.SECONDS);
        executor.shutdown();

        assertThat(responses).hasSize(threads);

        long ingestedCount = responses.stream().filter(r -> "INGESTED".equals(r.getStatus())).count();
        long alreadyProcessedCount = responses.stream().filter(r -> "ALREADY_PROCESSED".equals(r.getStatus())).count();

        // Exactly 1 thread must have INGESTED the event, others must be ALREADY_PROCESSED
        assertThat(ingestedCount).isEqualTo(1);
        assertThat(alreadyProcessedCount).isEqualTo(threads - 1);

        // Database must strictly contain only 1 record
        long dbCount = paymentEventRepository.findAll().stream()
                .filter(e -> e.getEventId().equals(eventId))
                .count();
        assertThat(dbCount).isEqualTo(1);
    }
}
