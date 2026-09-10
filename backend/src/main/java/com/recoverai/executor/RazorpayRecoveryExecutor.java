package com.recoverai.executor;

import com.recoverai.dto.ExecutionResult;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.model.enums.ExecutorType;
import com.recoverai.model.enums.RetryStatus;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component("razorpayRecoveryExecutor")
@Slf4j
public class RazorpayRecoveryExecutor implements RecoveryExecutor {

    @Override
    public ExecutorType getExecutorType() {
        return ExecutorType.RAZORPAY;
    }

    @Override
    public ExecutionResult executeRecovery(PaymentEvent event, int attemptNumber) {
        log.info("[RECOVERY EXECUTOR: RAZORPAY TEST-MODE] Re-submitting payment event {} for attempt {}",
                event.getEventId(), attemptNumber);

        // In test-mode: simulate payment capture attempt
        String rzpPaymentId = "pay_test_" + UUID.randomUUID().toString().replace("-", "").substring(0, 14);

        return ExecutionResult.builder()
                .status(RetryStatus.SUCCESS)
                .gatewayReferenceId(rzpPaymentId)
                .errorMessage(null)
                .executorType(ExecutorType.RAZORPAY)
                .attemptNumber(attemptNumber)
                .recoveredAmount(event.getAmount())
                .build();
    }
}
