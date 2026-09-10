package com.recoverai.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchResponse {
    private UUID id;
    private String batchName;
    private String status;
    private Integer totalEvents;
    private BigDecimal atRiskAmount;
    private BigDecimal diagnosedAmount;
    private BigDecimal interventionAmount;
    private BigDecimal recoveredAmount;
    private BigDecimal recoveryRate;
    private OffsetDateTime createdAt;
    private OffsetDateTime completedAt;
    private BatchFunnelMetrics funnelMetrics;
}
