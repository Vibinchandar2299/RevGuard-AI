package com.recoverai;

import com.recoverai.entity.*;
import com.recoverai.model.enums.*;
import com.recoverai.repository.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
class BackendPersistenceLayerTest {

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private RecoveryBatchRepository batchRepository;

    @Autowired
    private PaymentEventRepository paymentEventRepository;

    @Autowired
    private ClassificationRepository classificationRepository;

    @Autowired
    private RecoveryPolicyRepository policyRepository;

    @Autowired
    private RecoveryActionRepository actionRepository;

    @Autowired
    private RetryAttemptRepository retryAttemptRepository;

    @Autowired
    private RecoveryMessageRepository messageRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Test
    @DisplayName("Verify Spring Boot persistence layer reads seeded batch and policy data via JPA repositories")
    void testReadSeededDataViaJPA() {
        // 1. Verify Recovery Policies via JPA
        List<RecoveryPolicy> activePolicies = policyRepository.findByActiveTrue();
        assertThat(activePolicies).hasSize(6);

        Optional<RecoveryPolicy> insufficientFundsPolicy = policyRepository.findByReasonCodeAndActiveTrue("insufficient_funds");
        assertThat(insufficientFundsPolicy).isPresent();
        assertThat(insufficientFundsPolicy.get().getAction()).isEqualTo("RETRY");
        assertThat(insufficientFundsPolicy.get().getMaxAttempts()).isEqualTo(3);
        assertThat(insufficientFundsPolicy.get().getAmountCap()).isEqualByComparingTo("20000.00");

        // 2. Verify Recovery Batch via JPA
        Optional<RecoveryBatch> batchOpt = batchRepository.findByBatchName("BATCH-2026-SYNTH-01");
        assertThat(batchOpt).isPresent();
        RecoveryBatch batch = batchOpt.get();
        assertThat(batch.getTotalEvents()).isEqualTo(100);
        assertThat(batch.getAtRiskAmount()).isEqualByComparingTo("511870.00");
        assertThat(batch.getRecoveredAmount()).isEqualByComparingTo("353640.00");
        assertThat(batch.getRecoveryRate()).isEqualByComparingTo("69.09");

        // 3. Verify Payment Events via JPA
        List<PaymentEvent> events = paymentEventRepository.findByBatchId(batch.getId());
        assertThat(events).hasSize(100);

        // Verify entity relationships
        PaymentEvent sampleEvent = events.get(0);
        assertThat(sampleEvent.getCustomer()).isNotNull();
        assertThat(sampleEvent.getCustomer().getName()).isNotBlank();
        assertThat(sampleEvent.getBatch().getId()).isEqualTo(batch.getId());

        // 4. Verify Classifications via JPA
        Optional<Classification> clfOpt = classificationRepository.findByPaymentEventId(sampleEvent.getId());
        assertThat(clfOpt).isPresent();
        assertThat(clfOpt.get().getReasonCode()).isNotBlank();
        assertThat(clfOpt.get().getConfidence()).isGreaterThanOrEqualTo(BigDecimal.ZERO);

        // 5. Verify Audit Logs via JPA
        List<AuditLog> recentLogs = auditLogRepository.findTop50ByOrderByCreatedAtDesc();
        assertThat(recentLogs).isNotEmpty();
        assertThat(recentLogs.get(0).getActor()).isNotBlank();
    }

    @Test
    @DisplayName("Verify JPA write operations and relationship navigation across all entities")
    void testJPAWriteOperations() {
        // 1. Create and save Customer
        Customer customer = Customer.builder()
                .externalCustomerId("CUST-JPA-TEST")
                .name("Kavya Sharma")
                .email("kavya@example.com")
                .phone("+919123456780")
                .build();
        customer = customerRepository.save(customer);
        assertThat(customer.getId()).isNotNull();

        // 2. Create and save PaymentEvent
        PaymentEvent event = PaymentEvent.builder()
                .eventId("evt_jpa_test_" + System.currentTimeMillis())
                .customer(customer)
                .amount(new BigDecimal("7500.00"))
                .currency("INR")
                .paymentMethod("UPI")
                .rawFailureCode("ERR_INSUFFICIENT_FUNDS")
                .rawFailureMessage("Insufficient balance in UPI bank account")
                .status(PaymentStatus.INGESTED.name())
                .build();
        event = paymentEventRepository.save(event);
        assertThat(event.getId()).isNotNull();

        // 3. Create and save Classification
        Classification classification = Classification.builder()
                .paymentEvent(event)
                .reasonCode(ReasonCode.INSUFFICIENT_FUNDS.getValue())
                .confidence(new BigDecimal("0.9400"))
                .suggestedAction(ActionType.RETRY.name())
                .modelName("llama-3.3-70b-versatile")
                .rawResponse("{\"reason_code\":\"insufficient_funds\",\"confidence\":0.94}")
                .build();
        classification = classificationRepository.save(classification);
        assertThat(classification.getId()).isNotNull();

        // 4. Create and save RecoveryAction
        RecoveryAction action = RecoveryAction.builder()
                .paymentEvent(event)
                .actionType(ActionType.RETRY.name())
                .policyVersion(1)
                .policyReasonCode(ReasonCode.INSUFFICIENT_FUNDS.getValue())
                .decisionReason("Policy v1 allows retry for insufficient_funds with confidence >= 0.60")
                .authorizedAmount(new BigDecimal("7500.00"))
                .status("PENDING")
                .build();
        action = actionRepository.save(action);
        assertThat(action.getId()).isNotNull();

        // 5. Create and save RetryAttempt
        RetryAttempt attempt = RetryAttempt.builder()
                .paymentEvent(event)
                .attemptNumber(1)
                .executorType(ExecutorType.MOCK.name())
                .status(RetryStatus.SUCCESS.name())
                .gatewayReferenceId("mock_pay_jpa_001")
                .build();
        attempt = retryAttemptRepository.save(attempt);
        assertThat(attempt.getId()).isNotNull();

        // 6. Create and save AuditLog
        AuditLog log = AuditLog.builder()
                .paymentEvent(event)
                .actor(AuditActor.POLICY_ENGINE.name())
                .action("ACTION_DECIDED")
                .reason("Authorized retry attempt 1 under amount cap")
                .build();
        log = auditLogRepository.save(log);
        assertThat(log.getId()).isNotNull();

        // Verify retrieval
        assertThat(paymentEventRepository.existsByEventId(event.getEventId())).isTrue();
        assertThat(retryAttemptRepository.countByPaymentEventId(event.getId())).isEqualTo(1);
    }
}
