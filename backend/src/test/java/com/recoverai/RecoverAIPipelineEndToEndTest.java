package com.recoverai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.recoverai.dto.BatchRunRequest;
import com.recoverai.dto.MessageActionRequest;
import com.recoverai.dto.PaymentIngestionRequest;
import com.recoverai.entity.*;
import com.recoverai.model.enums.ActionType;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.*;
import com.recoverai.service.DraftService;
import com.recoverai.service.PolicyEngine;
import com.recoverai.service.RecoveryExecutionService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class RecoverAIPipelineEndToEndTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PaymentEventRepository paymentEventRepository;

    @Autowired
    private ClassificationRepository classificationRepository;

    @Autowired
    private RecoveryActionRepository actionRepository;

    @Autowired
    private RetryAttemptRepository retryAttemptRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private RecoveryMessageRepository messageRepository;

    @Autowired
    private RecoveryBatchRepository batchRepository;

    @Autowired
    private PolicyEngine policyEngine;

    @Autowired
    private RecoveryExecutionService executionService;

    @Autowired
    private DraftService draftService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @AfterEach
    void tearDown() {
        jdbcTemplate.update("DELETE FROM recovery_messages WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_e2e_%')");
        jdbcTemplate.update("DELETE FROM retry_attempts WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_e2e_%')");
        jdbcTemplate.update("DELETE FROM recovery_actions WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_e2e_%')");
        jdbcTemplate.update("DELETE FROM classifications WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_e2e_%')");
        jdbcTemplate.update("DELETE FROM audit_log WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_e2e_%')");
        jdbcTemplate.update("DELETE FROM payment_events WHERE event_id LIKE 'evt_e2e_%'");
        jdbcTemplate.update("DELETE FROM recovery_batches WHERE batch_name LIKE 'BATCH-E2E-%'");
        jdbcTemplate.update("DELETE FROM customers WHERE email LIKE 'e2e_%'");
    }

    @Test
    @DisplayName("E2E Stage 1 to 5: Ingestion -> AI Diagnosis -> Policy Engine -> Execution -> Recovery & Audit")
    void testFullAutonomousRecoveryPipeline() throws Exception {
        String eventId = "evt_e2e_net_" + UUID.randomUUID();

        PaymentIngestionRequest ingestionRequest = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("4200.00"))
                .currency("INR")
                .customerEmail("e2e_customer1@example.com")
                .customerName("Rohan Sharma")
                .paymentMethod("CARD")
                .rawFailureCode("network_timeout")
                .rawFailureMessage("Gateway timed out waiting for issuer response")
                .build();

        // Stage 1: Ingestion via REST API
        mockMvc.perform(post("/api/events/ingest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(ingestionRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.eventId").value(eventId))
                .andExpect(jsonPath("$.status").value("INGESTED"))
                .andExpect(jsonPath("$.duplicate").value(false));

        PaymentEvent event = paymentEventRepository.findByEventId(eventId).orElseThrow();
        assertThat(event.getStatus()).isEqualTo(PaymentStatus.INGESTED.name());

        // Stage 2: AI Diagnosis simulation
        Classification classification = classificationRepository.save(
                Classification.builder()
                        .paymentEvent(event)
                        .reasonCode("network_timeout")
                        .confidence(new BigDecimal("0.9600"))
                        .suggestedAction("RETRY")
                        .modelName("llama-3.3-70b-versatile")
                        .build()
        );

        // Stage 3: Deterministic Policy & Risk Decision Engine
        var decision = policyEngine.evaluate(event, classification);
        assertThat(decision.getActionType()).isEqualTo(ActionType.RETRY);
        assertThat(decision.getPolicyVersion()).isNotNull();
        assertThat(decision.getAuthorizedAmount()).isEqualByComparingTo(new BigDecimal("4200.00"));

        // Stage 4: Recovery Executor (Mock)
        var executionResult = executionService.executeRetry(event, 1);
        assertThat(executionResult.getStatus().name()).isEqualTo("SUCCESS");
        assertThat(executionResult.getGatewayReferenceId()).startsWith("mock_pay_");

        // Verify Event state transitioned to RECOVERED
        PaymentEvent recoveredEvent = paymentEventRepository.findByEventId(eventId).orElseThrow();
        assertThat(recoveredEvent.getStatus()).isEqualTo(PaymentStatus.RECOVERED.name());

        // Stage 5: Chronological Audit Log Verification
        List<AuditLog> auditLogs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(auditLogs).isNotEmpty();
        assertThat(auditLogs).anyMatch(l -> "PAYMENT_INGESTED".equals(l.getAction()) && "SYSTEM".equals(l.getActor()));
        assertThat(auditLogs).anyMatch(l -> "ACTION_DECIDED".equals(l.getAction()) && AuditActor.POLICY_ENGINE.name().equals(l.getActor()));
        assertThat(auditLogs).anyMatch(l -> "RETRY_SUCCESS".equals(l.getAction()) && "SYSTEM".equals(l.getActor()));
    }

    @Test
    @DisplayName("E2E Safety Rule: Zero confidence blocks autonomous action and routes to human review")
    void testZeroConfidenceSafetyBlockE2E() throws Exception {
        String eventId = "evt_e2e_zero_conf_" + UUID.randomUUID();

        PaymentIngestionRequest req = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("2500.00"))
                .currency("INR")
                .customerEmail("e2e_zero_conf@example.com")
                .customerName("Anita Deshmukh")
                .paymentMethod("CARD")
                .rawFailureCode("unknown_glitch")
                .rawFailureMessage("Unexpected system error")
                .build();

        mockMvc.perform(post("/api/events/ingest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        PaymentEvent event = paymentEventRepository.findByEventId(eventId).orElseThrow();

        // Simulate failed Groq classification (confidence = 0)
        Classification zeroConfClf = classificationRepository.save(
                Classification.builder()
                        .paymentEvent(event)
                        .reasonCode("other")
                        .confidence(BigDecimal.ZERO)
                        .suggestedAction("ESCALATE")
                        .modelName("llama-3.3-70b-versatile")
                        .build()
        );

        // Policy engine MUST block autonomous retry
        var decision = policyEngine.evaluate(event, zeroConfClf);
        assertThat(decision.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getDecisionReason()).contains("Zero-confidence safety block");

        // Verify event escalated and zero retry attempts made
        PaymentEvent updated = paymentEventRepository.findByEventId(eventId).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.ESCALATED.name());
        assertThat(retryAttemptRepository.countByPaymentEventId(event.getId())).isZero();
    }

    @Test
    @DisplayName("E2E Safety Rule: Amount > Rs20,000 blocks autonomous retry and requires human authorization")
    void testAmountCapSafetyBlockE2E() throws Exception {
        String eventId = "evt_e2e_cap_" + UUID.randomUUID();

        PaymentIngestionRequest req = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("35000.00")) // Exceeds Rs 20,000 cap
                .currency("INR")
                .customerEmail("e2e_cap@example.com")
                .customerName("Vikram Enterprises")
                .paymentMethod("CARD")
                .rawFailureCode("network_timeout")
                .rawFailureMessage("Timeout")
                .build();

        mockMvc.perform(post("/api/events/ingest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        PaymentEvent event = paymentEventRepository.findByEventId(eventId).orElseThrow();

        Classification clf = classificationRepository.save(
                Classification.builder()
                        .paymentEvent(event)
                        .reasonCode("network_timeout")
                        .confidence(new BigDecimal("0.9900"))
                        .suggestedAction("RETRY")
                        .modelName("llama-3.3-70b-versatile")
                        .build()
        );

        var decision = policyEngine.evaluate(event, clf);
        assertThat(decision.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getDecisionReason()).contains("Autonomous amount cap exceeded");

        PaymentEvent updated = paymentEventRepository.findByEventId(eventId).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.ESCALATED.name());
        assertThat(retryAttemptRepository.countByPaymentEventId(event.getId())).isZero();
    }

    @Test
    @DisplayName("E2E Messaging & Human-in-the-Loop Review: Draft -> Review -> Approve via REST API")
    void testHumanInTheLoopMessagingReviewE2E() throws Exception {
        String eventId = "evt_e2e_msg_" + UUID.randomUUID();

        PaymentIngestionRequest req = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("1999.00"))
                .currency("INR")
                .customerEmail("e2e_msg_user@example.com")
                .customerName("Kavita Nair")
                .paymentMethod("CARD")
                .rawFailureCode("card_expired")
                .rawFailureMessage("Card validity expired")
                .build();

        mockMvc.perform(post("/api/events/ingest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        PaymentEvent event = paymentEventRepository.findByEventId(eventId).orElseThrow();

        // Create message draft
        RecoveryMessage draft = draftService.createDraftForEvent(event);
        assertThat(draft.getStatus()).isEqualTo("DRAFTED");

        // Verify draft appears in GET /api/messages/drafts
        mockMvc.perform(get("/api/messages/drafts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.eventId == '" + eventId + "')].status").value("DRAFTED"));

        // Human reviewer approves draft via POST /api/messages/{id}/approve
        MessageActionRequest approveReq = MessageActionRequest.builder()
                .reviewer("RiskSpecialist_Arun")
                .comments("Verified new card token added by customer")
                .build();

        mockMvc.perform(post("/api/messages/" + draft.getId() + "/approve")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(approveReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SENT"));

        // Verify database and audit log
        RecoveryMessage sentMessage = messageRepository.findById(draft.getId()).orElseThrow();
        assertThat(sentMessage.getStatus()).isEqualTo("SENT");
        assertThat(sentMessage.getSentAt()).isNotNull();

        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "MESSAGE_APPROVED".equals(l.getAction())
                && AuditActor.HUMAN.name().equals(l.getActor())
                && l.getReason().contains("RiskSpecialist_Arun"));
    }

    @Test
    @DisplayName("E2E Batch & Funnel REST APIs: Run batch and verify stage funnel metrics")
    void testBatchRunAndFunnelMetricsE2E() throws Exception {
        String eventId = "evt_e2e_batch_" + UUID.randomUUID();

        PaymentIngestionRequest req = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(new BigDecimal("5000.00"))
                .currency("INR")
                .customerEmail("e2e_batch_user@example.com")
                .customerName("Batch Corp")
                .paymentMethod("CARD")
                .rawFailureCode("network_timeout")
                .rawFailureMessage("Timeout")
                .build();

        mockMvc.perform(post("/api/events/ingest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        BatchRunRequest batchRun = BatchRunRequest.builder()
                .batchName("BATCH-E2E-" + UUID.randomUUID())
                .eventIds(List.of(eventId))
                .executeRetries(true)
                .build();

        // Trigger batch run via REST API
        String batchRespJson = mockMvc.perform(post("/api/batches/run")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(batchRun)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.totalEvents").value(1))
                .andExpect(jsonPath("$.recoveredAmount").value(5000.00))
                .andExpect(jsonPath("$.recoveryRate").value(100.00))
                .andReturn().getResponse().getContentAsString();

        UUID batchId = UUID.fromString(objectMapper.readTree(batchRespJson).get("id").asText());

        // Verify Funnel API
        mockMvc.perform(get("/api/batches/" + batchId + "/funnel"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalEvents").value(1))
                .andExpect(jsonPath("$.recoveredEvents").value(1))
                .andExpect(jsonPath("$.recoveryRate").value(100.00));
    }

    @Test
    @DisplayName("E2E Dashboard REST APIs: Executive summary, reason breakdown, and audit feed")
    void testDashboardAPIsE2E() throws Exception {
        // Summary
        mockMvc.perform(get("/api/dashboard/summary"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalEvents").isNumber())
                .andExpect(jsonPath("$.totalAtRiskAmount").isNumber())
                .andExpect(jsonPath("$.totalRecoveredAmount").isNumber())
                .andExpect(jsonPath("$.activePoliciesCount").value(6));

        // Reasons breakdown
        mockMvc.perform(get("/api/dashboard/reasons"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[?(@.reasonCode == 'network_timeout')]").exists())
                .andExpect(jsonPath("$[?(@.reasonCode == 'insufficient_funds')]").exists());

        // Audit feed
        mockMvc.perform(get("/api/dashboard/audit-feed?limit=10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }
}
