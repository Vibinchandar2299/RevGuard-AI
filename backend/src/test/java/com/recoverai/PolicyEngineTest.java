package com.recoverai;

import com.recoverai.dto.PolicyDecision;
import com.recoverai.entity.*;
import com.recoverai.model.enums.*;
import com.recoverai.repository.*;
import com.recoverai.service.PolicyEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class PolicyEngineTest {

    @Autowired
    private PolicyEngine policyEngine;

    @Autowired
    private CustomerRepository customerRepository;

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

    private Customer customer;

    @BeforeEach
    void setUp() {
        customer = customerRepository.save(
                Customer.builder()
                        .name("Policy Test Customer")
                        .email("policy_test_" + UUID.randomUUID() + "@example.com")
                        .build()
        );
    }

    private PaymentEvent createEvent(BigDecimal amount) {
        return paymentEventRepository.save(
                PaymentEvent.builder()
                        .eventId("evt_pol_" + UUID.randomUUID())
                        .customer(customer)
                        .amount(amount)
                        .currency("INR")
                        .paymentMethod("CARD")
                        .rawFailureCode("GENERIC_FAIL")
                        .status(PaymentStatus.INGESTED.name())
                        .build()
        );
    }

    private Classification createClassification(PaymentEvent event, String reasonCode, BigDecimal confidence, String suggestedAction) {
        return classificationRepository.save(
                Classification.builder()
                        .paymentEvent(event)
                        .reasonCode(reasonCode)
                        .confidence(confidence)
                        .suggestedAction(suggestedAction)
                        .build()
        );
    }

    @Test
    @DisplayName("NON-NEGOTIABLE SAFETY RULE: Zero confidence MUST block any autonomous action and route to human review")
    void testZeroConfidenceSafetyBlock() {
        PaymentEvent event = createEvent(new BigDecimal("1500.00"));

        // Case A: Classification with confidence = 0.0000
        Classification zeroConfClf = createClassification(event, "insufficient_funds", BigDecimal.ZERO, "RETRY");

        PolicyDecision decision = policyEngine.evaluate(event, zeroConfClf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getDecisionReason()).contains("Zero-confidence safety block");

        // Verify audit log has actor=POLICY_ENGINE
        List<AuditLog> auditLogs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(auditLogs).isNotEmpty();
        assertThat(auditLogs.get(0).getActor()).isEqualTo(AuditActor.POLICY_ENGINE.name());
        assertThat(auditLogs.get(0).getReason()).contains("Zero-confidence safety block");

        // Verify event status is updated to ESCALATED
        PaymentEvent updated = paymentEventRepository.findById(event.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.ESCALATED.name());

        // Case B: Null classification (LLM completely failed/unavailable)
        PaymentEvent event2 = createEvent(new BigDecimal("2000.00"));
        PolicyDecision decisionNull = policyEngine.evaluate(event2, null);
        assertThat(decisionNull.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decisionNull.getDecisionReason()).contains("Zero-confidence safety block");
    }

    @Test
    @DisplayName("Verify confidence below minimum policy threshold escalates to human review")
    void testConfidenceBelowThresholdEscalates() {
        PaymentEvent event = createEvent(new BigDecimal("4000.00"));
        // insufficient_funds requires min_confidence = 0.60. Here confidence = 0.50
        Classification clf = createClassification(event, "insufficient_funds", new BigDecimal("0.5000"), "RETRY");

        PolicyDecision decision = policyEngine.evaluate(event, clf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getDecisionReason()).contains("Confidence threshold breach");
    }

    @Test
    @DisplayName("Verify amount exceeding autonomous cap Rs20,000 escalates to human review")
    void testAmountCapExceededEscalates() {
        // Amount Rs 25,000 exceeds autonomous cap of Rs 20,000
        PaymentEvent event = createEvent(new BigDecimal("25000.00"));
        Classification clf = createClassification(event, "insufficient_funds", new BigDecimal("0.9500"), "RETRY");

        PolicyDecision decision = policyEngine.evaluate(event, clf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getDecisionReason()).contains("Autonomous amount cap exceeded");
    }

    @Test
    @DisplayName("Verify valid insufficient_funds under cap with high confidence authorizes RETRY")
    void testValidInsufficientFundsRetries() {
        PaymentEvent event = createEvent(new BigDecimal("8500.00"));
        Classification clf = createClassification(event, "insufficient_funds", new BigDecimal("0.9200"), "RETRY");

        PolicyDecision decision = policyEngine.evaluate(event, clf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.RETRY);
        assertThat(decision.getAuthorizedAmount()).isEqualByComparingTo("8500.00");
        assertThat(decision.getPolicyVersion()).isEqualTo(1);
        assertThat(decision.getCooldownSeconds()).isEqualTo(60);
        assertThat(decision.getPolicyReasonCode()).isEqualTo("insufficient_funds");

        // Verify recovery_actions persistence with policy_version
        List<RecoveryAction> actions = actionRepository.findByPaymentEventId(event.getId());
        assertThat(actions).hasSize(1);
        assertThat(actions.get(0).getPolicyVersion()).isEqualTo(1);
        assertThat(actions.get(0).getActionType()).isEqualTo("RETRY");
    }

    @Test
    @DisplayName("Verify card_expired determines REQUEST_UPDATE and zero retry attempts")
    void testCardExpiredRequestsUpdate() {
        PaymentEvent event = createEvent(new BigDecimal("1200.00"));
        Classification clf = createClassification(event, "card_expired", new BigDecimal("0.9500"), "REQUEST_UPDATE");

        PolicyDecision decision = policyEngine.evaluate(event, clf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.REQUEST_UPDATE);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getMaxAttempts()).isEqualTo(0);
    }

    @Test
    @DisplayName("Verify fraud_suspected determines BLOCK and zero retry attempts")
    void testFraudSuspectedBlocks() {
        PaymentEvent event = createEvent(new BigDecimal("15000.00"));
        Classification clf = createClassification(event, "fraud_suspected", new BigDecimal("0.9800"), "BLOCK");

        PolicyDecision decision = policyEngine.evaluate(event, clf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.BLOCK);
        assertThat(decision.getAuthorizedAmount()).isNull();
        assertThat(decision.getMaxAttempts()).isEqualTo(0);
    }

    @Test
    @DisplayName("Verify retry count limit exceeded escalates to human review")
    void testRetryCountExceededEscalates() {
        PaymentEvent event = createEvent(new BigDecimal("3000.00"));
        Classification clf = createClassification(event, "insufficient_funds", new BigDecimal("0.9000"), "RETRY");

        // Record 3 previous attempts (max for insufficient_funds is 3)
        for (int i = 1; i <= 3; i++) {
            retryAttemptRepository.save(
                    RetryAttempt.builder()
                            .paymentEvent(event)
                            .attemptNumber(i)
                            .executorType(ExecutorType.MOCK.name())
                            .status(RetryStatus.FAILED.name())
                            .build()
            );
        }

        PolicyDecision decision = policyEngine.evaluate(event, clf);

        assertThat(decision.getActionType()).isEqualTo(ActionType.ESCALATE);
        assertThat(decision.getDecisionReason()).contains("Retry count exceeded");
    }
}
