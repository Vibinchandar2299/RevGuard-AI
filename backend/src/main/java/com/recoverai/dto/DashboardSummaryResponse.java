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
public class DashboardSummaryResponse {
    private BigDecimal totalAtRiskAmount;
    private BigDecimal totalRecoveredAmount;
    private BigDecimal aggregateRecoveryRate;
    private int totalEvents;
    private int recoveredEventsCount;
    private int failedEventsCount;
    private int activePoliciesCount;
    private int pendingHumanReviewsCount;
}
