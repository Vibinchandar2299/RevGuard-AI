package com.recoverai.service;

import com.recoverai.config.RecoveryProperties;
import com.recoverai.dto.ExecutionResult;
import com.recoverai.entity.AuditLog;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.entity.RecoveryPolicy;
import com.recoverai.entity.RetryAttempt;
import com.recoverai.executor.MockRecoveryExecutor;
import com.recoverai.executor.RazorpayRecoveryExecutor;
import com.recoverai.executor.RecoveryExecutor;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.model.enums.RetryStatus;
import com.recoverai.repository.AuditLogRepository;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.repository.RecoveryPolicyRepository;
import com.recoverai.repository.RetryAttemptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.Optional;

/**
 * Stage 4: Recovery Executor.
 * Executes retry actions using the active RecoveryExecutor (Mock or Razorpay).
 * Guarantees strict respect of UNIQUE(payment_event_id, attempt_number).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RecoveryExecutionService {

    private final MockRecoveryExecutor mockRecoveryExecutor;
    private final RazorpayRecoveryExecutor razorpayRecoveryExecutor;
    private final RecoveryProperties recoveryProperties;
    private final RetryAttemptRepository retryAttemptRepository;
    private final PaymentEventRepository paymentEventRepository;
    private final RecoveryPolicyRepository policyRepository;
    private final AuditLogRepository auditLogRepository;
    private final TransactionTemplate transactionTemplate;

    /**
     * Resolves the active executor based on config flag: recovery.executor=mock|razorpay
     */
    public RecoveryExecutor getActiveExecutor() {
        if ("razorpay".equalsIgnoreCase(recoveryProperties.getExecutor())) {
            return razorpayRecoveryExecutor;
        }
        return mockRecoveryExecutor;
    }

    public ExecutionResult executeRetry(PaymentEvent event, int attemptNumber) {
        log.info("[STAGE 4: RECOVERY EXECUTOR] Initiating retry attempt {} for event {}", attemptNumber, event.getEventId());

        // Fast-path duplicate attempt check
        Optional<RetryAttempt> existingAttempt = retryAttemptRepository.findByPaymentEventIdAndAttemptNumber(event.getId(), attemptNumber);
        if (existingAttempt.isPresent()) {
            log.warn("[STAGE 4: RECOVERY EXECUTOR] Retry attempt {} already recorded for event {}. Preventing double-execution.",
                    attemptNumber, event.getEventId());
            RetryAttempt existing = existingAttempt.get();
            return ExecutionResult.builder()
                    .attemptNumber(attemptNumber)
                    .status(RetryStatus.valueOf(existing.getStatus()))
                    .gatewayReferenceId(existing.getGatewayReferenceId())
                    .errorMessage(existing.getErrorMessage())
                    .executorType(com.recoverai.model.enums.ExecutorType.valueOf(existing.getExecutorType()))
                    .recoveredAmount("SUCCESS".equals(existing.getStatus()) ? event.getAmount() : null)
                    .build();
        }

        RecoveryExecutor executor = getActiveExecutor();
        ExecutionResult result = executor.executeRecovery(event, attemptNumber);

        try {
            return transactionTemplate.execute(txStatus -> {
                // Check once more inside transaction boundary
                Optional<RetryAttempt> innerAttempt = retryAttemptRepository.findByPaymentEventIdAndAttemptNumber(event.getId(), attemptNumber);
                if (innerAttempt.isPresent()) {
                    RetryAttempt existing = innerAttempt.get();
                    return ExecutionResult.builder()
                            .attemptNumber(attemptNumber)
                            .status(RetryStatus.valueOf(existing.getStatus()))
                            .gatewayReferenceId(existing.getGatewayReferenceId())
                            .errorMessage(existing.getErrorMessage())
                            .executorType(com.recoverai.model.enums.ExecutorType.valueOf(existing.getExecutorType()))
                            .recoveredAmount("SUCCESS".equals(existing.getStatus()) ? event.getAmount() : null)
                            .build();
                }

                // Persist RetryAttempt record respecting UNIQUE(payment_event_id, attempt_number)
                RetryAttempt attempt = RetryAttempt.builder()
                        .paymentEvent(event)
                        .attemptNumber(attemptNumber)
                        .executorType(result.getExecutorType().name())
                        .status(result.getStatus().name())
                        .gatewayReferenceId(result.getGatewayReferenceId())
                        .errorMessage(result.getErrorMessage())
                        .build();
                retryAttemptRepository.saveAndFlush(attempt);

                // Handle outcomes and state transitions
                PaymentEvent managedEvent = paymentEventRepository.findById(event.getId()).orElse(event);
                if (result.getStatus() == RetryStatus.SUCCESS) {
                    managedEvent.setStatus(PaymentStatus.RECOVERED.name());
                    paymentEventRepository.save(managedEvent);

                    auditLogRepository.save(AuditLog.builder()
                            .paymentEvent(managedEvent)
                            .actor(AuditActor.SYSTEM.name())
                            .action("RETRY_SUCCESS")
                            .reason(String.format("Payment of Rs %.2f successfully recovered via %s on attempt %d (ref: %s)",
                                    managedEvent.getAmount(), result.getExecutorType(), attemptNumber, result.getGatewayReferenceId()))
                            .build());

                    log.info("[STAGE 4: RECOVERY EXECUTOR] Event {} successfully RECOVERED on attempt {} via {}",
                            managedEvent.getEventId(), attemptNumber, result.getExecutorType());

                } else {
                    // Determine if retries are exhausted
                    int maxAttempts = 3;
                    Optional<RecoveryPolicy> policyOpt = policyRepository.findByReasonCodeAndActiveTrue(managedEvent.getRawFailureCode());
                    if (policyOpt.isPresent() && policyOpt.get().getMaxAttempts() != null) {
                        maxAttempts = policyOpt.get().getMaxAttempts();
                    }

                    if (attemptNumber >= maxAttempts) {
                        managedEvent.setStatus(PaymentStatus.FAILED.name());
                        paymentEventRepository.save(managedEvent);

                        auditLogRepository.save(AuditLog.builder()
                                .paymentEvent(managedEvent)
                                .actor(AuditActor.SYSTEM.name())
                                .action("RETRY_EXHAUSTED")
                                .reason(String.format("All %d retry attempts exhausted without recovery; event marked as FAILED", maxAttempts))
                                .build());

                        log.warn("[STAGE 4: RECOVERY EXECUTOR] Event {} retries exhausted ({}/{}); marked as FAILED",
                                managedEvent.getEventId(), attemptNumber, maxAttempts);
                    } else {
                        managedEvent.setStatus(PaymentStatus.RETRY_SCHEDULED.name());
                        paymentEventRepository.save(managedEvent);

                        auditLogRepository.save(AuditLog.builder()
                                .paymentEvent(managedEvent)
                                .actor(AuditActor.SYSTEM.name())
                                .action("RETRY_FAILED")
                                .reason(String.format("Retry attempt %d failed via %s: %s; scheduled for next cooldown cycle",
                                        attemptNumber, result.getExecutorType(), result.getErrorMessage()))
                                .build());
                    }
                }

                return result;
            });

        } catch (DataIntegrityViolationException ex) {
            log.warn("[STAGE 4: RECOVERY EXECUTOR] Caught unique constraint violation on retry_attempts for event {} attempt {}",
                    event.getEventId(), attemptNumber);
            return retryAttemptRepository.findByPaymentEventIdAndAttemptNumber(event.getId(), attemptNumber)
                    .map(a -> ExecutionResult.builder()
                            .attemptNumber(attemptNumber)
                            .status(RetryStatus.valueOf(a.getStatus()))
                            .gatewayReferenceId(a.getGatewayReferenceId())
                            .errorMessage(a.getErrorMessage())
                            .executorType(com.recoverai.model.enums.ExecutorType.valueOf(a.getExecutorType()))
                            .recoveredAmount("SUCCESS".equals(a.getStatus()) ? event.getAmount() : null)
                            .build())
                    .orElseThrow(() -> ex);
        }
    }
}
