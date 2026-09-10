package com.recoverai.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchFunnelMetrics {
    private int totalEvents;
    private BigDecimal atRiskAmount;
    private int diagnosedEvents;
    private BigDecimal diagnosedAmount;
    private int policyApprovedEvents;
    private BigDecimal policyInterventionAmount;
    private int retryExecutedEvents;
    private int recoveredEvents;
    private BigDecimal recoveredAmount;
    private int failedEvents;
    private int pendingHumanReviewEvents;
    private BigDecimal recoveryRate;
}
