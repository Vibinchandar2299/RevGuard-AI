package com.recoverai.dto;

import com.recoverai.model.enums.ExecutorType;
import com.recoverai.model.enums.RetryStatus;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExecutionResult {

    private RetryStatus status;
    private String gatewayReferenceId;
    private String errorMessage;
    private ExecutorType executorType;
    private int attemptNumber;
    private BigDecimal recoveredAmount;
}
