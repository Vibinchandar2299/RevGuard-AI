package com.recoverai.executor;

import com.recoverai.dto.ExecutionResult;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.model.enums.ExecutorType;

/**
 * Pluggable recovery executor interface.
 * Implementations execute automated retries against mock simulator or real test-mode gateways.
 */
public interface RecoveryExecutor {

    /**
     * The type of executor (MOCK or RAZORPAY)
     */
    ExecutorType getExecutorType();

    /**
     * Executes recovery retry for the specified payment event and attempt number.
     */
    ExecutionResult executeRecovery(PaymentEvent event, int attemptNumber);
}
