package com.recoverai.executor;

import com.recoverai.dto.ExecutionResult;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.model.enums.ExecutorType;
import com.recoverai.model.enums.RetryStatus;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component("mockRecoveryExecutor")
@Slf4j
public class MockRecoveryExecutor implements RecoveryExecutor {

    // Test hook for deterministic testing
    private volatile RetryStatus forcedStatus = null;

    public void setForcedStatus(RetryStatus status) {
        this.forcedStatus = status;
    }

    public void clearForcedStatus() {
        this.forcedStatus = null;
    }

    @Override
    public ExecutorType getExecutorType() {
        return ExecutorType.MOCK;
    }

    @Override
    public ExecutionResult executeRecovery(PaymentEvent event, int attemptNumber) {
        log.info("[RECOVERY EXECUTOR: MOCK] Executing retry attempt {} for event {} (amount: Rs {})",
                attemptNumber, event.getEventId(), event.getAmount());

        if (forcedStatus != null) {
            return buildResult(event, attemptNumber, forcedStatus,
                    forcedStatus == RetryStatus.SUCCESS ? null : "Forced test failure");
        }

        String failureCode = event.getRawFailureCode() != null ? event.getRawFailureCode().toLowerCase() : "";

        // Deterministic realistic outcomes:
        // network_timeout: transient issue, succeeds on first retry
        if (failureCode.contains("network") || failureCode.contains("timeout")) {
            return buildResult(event, attemptNumber, RetryStatus.SUCCESS, null);
        }

        // insufficient_funds: succeeds if attemptNumber <= 2
        if (failureCode.contains("insufficient") || failureCode.contains("fund")) {
            if (attemptNumber <= 2) {
                return buildResult(event, attemptNumber, RetryStatus.SUCCESS, null);
            } else {
                return buildResult(event, attemptNumber, RetryStatus.FAILED, "Account balance still insufficient");
            }
        }

        // bank_declined: succeeds on attempt 2 after bank sync
        if (failureCode.contains("bank") || failureCode.contains("decline")) {
            if (attemptNumber == 2) {
                return buildResult(event, attemptNumber, RetryStatus.SUCCESS, null);
            } else {
                return buildResult(event, attemptNumber, RetryStatus.FAILED, "Bank policy rejection on attempt " + attemptNumber);
            }
        }

        // Default: success on attempt 1 for other recoverable reasons
        return buildResult(event, attemptNumber, RetryStatus.SUCCESS, null);
    }

    private ExecutionResult buildResult(PaymentEvent event, int attemptNumber, RetryStatus status, String error) {
        String refId = "mock_pay_" + UUID.randomUUID().toString().substring(0, 12);
        return ExecutionResult.builder()
                .status(status)
                .gatewayReferenceId(refId)
                .errorMessage(error)
                .executorType(ExecutorType.MOCK)
                .attemptNumber(attemptNumber)
                .recoveredAmount(status == RetryStatus.SUCCESS ? event.getAmount() : null)
                .build();
    }
}
