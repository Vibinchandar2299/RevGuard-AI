package com.recoverai;

import com.recoverai.config.RecoveryProperties;
import com.recoverai.dto.ExecutionResult;
import com.recoverai.entity.*;
import com.recoverai.executor.MockRecoveryExecutor;
import com.recoverai.executor.RazorpayRecoveryExecutor;
import com.recoverai.model.enums.*;
import com.recoverai.repository.*;
import com.recoverai.service.RecoveryExecutionService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
class RecoveryExecutionTest {

    @Autowired
    private RecoveryExecutionService recoveryExecutionService;

    @Autowired
    private MockRecoveryExecutor mockRecoveryExecutor;

    @Autowired
    private RazorpayRecoveryExecutor razorpayRecoveryExecutor;

    @Autowired
    private RecoveryProperties recoveryProperties;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private PaymentEventRepository paymentEventRepository;

    @Autowired
    private RetryAttemptRepository retryAttemptRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Customer testCustomer;

    @BeforeEach
    void setUp() {
        mockRecoveryExecutor.clearForcedStatus();
        recoveryProperties.setExecutor("mock");
        testCustomer = customerRepository.save(
                Customer.builder()
                        .name("Exec Test Customer")
                        .email("exec_test_" + UUID.randomUUID() + "@example.com")
                        .build()
        );
    }

    @AfterEach
    void tearDown() {
        mockRecoveryExecutor.clearForcedStatus();
        recoveryProperties.setExecutor("mock");
        jdbcTemplate.update("DELETE FROM retry_attempts WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_exec_%')");
        jdbcTemplate.update("DELETE FROM audit_log WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_exec_%')");
        jdbcTemplate.update("DELETE FROM payment_events WHERE event_id LIKE 'evt_exec_%'");
        jdbcTemplate.update("DELETE FROM customers WHERE email LIKE 'exec_test_%'");
    }

    private PaymentEvent createEvent(String reasonCode, BigDecimal amount) {
        return paymentEventRepository.save(
                PaymentEvent.builder()
                        .eventId("evt_exec_" + UUID.randomUUID())
                        .customer(testCustomer)
                        .amount(amount)
                        .currency("INR")
                        .paymentMethod("CARD")
                        .rawFailureCode(reasonCode)
                        .rawFailureMessage("Simulated failure for " + reasonCode)
                        .status(PaymentStatus.RETRY_SCHEDULED.name())
                        .build()
        );
    }

    @Test
    @DisplayName("Stage 4: Successful retry transitions event to RECOVERED and creates retry_attempts + audit_log")
    void testMockExecutor_SuccessfulRetry_TransitionsToRecovered() {
        PaymentEvent event = createEvent("network_timeout", new BigDecimal("4500.00"));

        ExecutionResult result = recoveryExecutionService.executeRetry(event, 1);

        assertThat(result.getStatus()).isEqualTo(RetryStatus.SUCCESS);
        assertThat(result.getAttemptNumber()).isEqualTo(1);
        assertThat(result.getGatewayReferenceId()).startsWith("mock_pay_");
        assertThat(result.getRecoveredAmount()).isEqualByComparingTo(new BigDecimal("4500.00"));

        // Verify DB updates
        PaymentEvent updated = paymentEventRepository.findById(event.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.RECOVERED.name());

        List<RetryAttempt> attempts = retryAttemptRepository.findByPaymentEventId(event.getId());
        assertThat(attempts).hasSize(1);
        assertThat(attempts.get(0).getAttemptNumber()).isEqualTo(1);
        assertThat(attempts.get(0).getStatus()).isEqualTo("SUCCESS");
        assertThat(attempts.get(0).getExecutorType()).isEqualTo("MOCK");

        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "RETRY_SUCCESS".equals(l.getAction()) && "SYSTEM".equals(l.getActor()));
    }

    @Test
    @DisplayName("Stage 4: Failed retry under max_attempts leaves event in RETRY_SCHEDULED")
    void testMockExecutor_FailedRetry_UnderMaxAttempts_TransitionsToRetryScheduled() {
        PaymentEvent event = createEvent("insufficient_funds", new BigDecimal("3500.00"));
        mockRecoveryExecutor.setForcedStatus(RetryStatus.FAILED);

        ExecutionResult result = recoveryExecutionService.executeRetry(event, 1);

        assertThat(result.getStatus()).isEqualTo(RetryStatus.FAILED);
        assertThat(result.getAttemptNumber()).isEqualTo(1);

        PaymentEvent updated = paymentEventRepository.findById(event.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.RETRY_SCHEDULED.name());

        List<RetryAttempt> attempts = retryAttemptRepository.findByPaymentEventId(event.getId());
        assertThat(attempts).hasSize(1);
        assertThat(attempts.get(0).getStatus()).isEqualTo("FAILED");

        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "RETRY_FAILED".equals(l.getAction()) && "SYSTEM".equals(l.getActor()));
    }

    @Test
    @DisplayName("Stage 4: Failed retry reaching max_attempts marks event as FAILED")
    void testMockExecutor_FailedRetry_MaxAttemptsExhausted_TransitionsToFailed() {
        PaymentEvent event = createEvent("insufficient_funds", new BigDecimal("3500.00"));
        mockRecoveryExecutor.setForcedStatus(RetryStatus.FAILED);

        // Attempt 3 out of 3
        ExecutionResult result = recoveryExecutionService.executeRetry(event, 3);

        assertThat(result.getStatus()).isEqualTo(RetryStatus.FAILED);
        assertThat(result.getAttemptNumber()).isEqualTo(3);

        PaymentEvent updated = paymentEventRepository.findById(event.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.FAILED.name());

        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "RETRY_EXHAUSTED".equals(l.getAction()) && "SYSTEM".equals(l.getActor()));
    }

    @Test
    @DisplayName("Stage 4: Prevent duplicate execution for same attempt number (idempotency)")
    void testPreventDuplicateAttemptExecution() {
        PaymentEvent event = createEvent("network_timeout", new BigDecimal("2000.00"));

        ExecutionResult res1 = recoveryExecutionService.executeRetry(event, 1);
        assertThat(res1.getStatus()).isEqualTo(RetryStatus.SUCCESS);

        // Attempt to execute the same attempt number again
        ExecutionResult res2 = recoveryExecutionService.executeRetry(event, 1);
        assertThat(res2.getStatus()).isEqualTo(RetryStatus.SUCCESS);
        assertThat(res2.getGatewayReferenceId()).isEqualTo(res1.getGatewayReferenceId());

        // Ensure only one retry_attempts row exists
        List<RetryAttempt> attempts = retryAttemptRepository.findByPaymentEventId(event.getId());
        assertThat(attempts).hasSize(1);
    }

    @Test
    @DisplayName("Stage 4: Database enforces UNIQUE(payment_event_id, attempt_number)")
    void testDatabaseLevelUniqueConstraint_ThrowsDataIntegrityViolationException() {
        PaymentEvent event = createEvent("bank_declined", new BigDecimal("1500.00"));

        RetryAttempt attempt1 = RetryAttempt.builder()
                .paymentEvent(event)
                .attemptNumber(1)
                .executorType("MOCK")
                .status("FAILED")
                .build();
        retryAttemptRepository.saveAndFlush(attempt1);

        RetryAttempt attempt2 = RetryAttempt.builder()
                .paymentEvent(event)
                .attemptNumber(1)
                .executorType("MOCK")
                .status("SUCCESS")
                .build();

        assertThatThrownBy(() -> retryAttemptRepository.saveAndFlush(attempt2))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Stage 4: Pluggable executor switches cleanly between Mock and Razorpay")
    void testPluggableExecutorSwitching() {
        assertThat(recoveryExecutionService.getActiveExecutor().getExecutorType()).isEqualTo(ExecutorType.MOCK);

        recoveryProperties.setExecutor("razorpay");
        assertThat(recoveryExecutionService.getActiveExecutor().getExecutorType()).isEqualTo(ExecutorType.RAZORPAY);

        PaymentEvent event = createEvent("network_timeout", new BigDecimal("8000.00"));
        ExecutionResult result = recoveryExecutionService.executeRetry(event, 1);

        assertThat(result.getExecutorType()).isEqualTo(ExecutorType.RAZORPAY);
        assertThat(result.getStatus()).isEqualTo(RetryStatus.SUCCESS);
        assertThat(result.getGatewayReferenceId()).startsWith("pay_test_");

        PaymentEvent updated = paymentEventRepository.findById(event.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.RECOVERED.name());
    }
}
