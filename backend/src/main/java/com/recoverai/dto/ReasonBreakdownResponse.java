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
public class ReasonBreakdownResponse {
    private String reasonCode;
    private String reasonDescription;
    private int count;
    private BigDecimal atRiskAmount;
    private BigDecimal recoveredAmount;
    private BigDecimal recoveryRate;
    private double successRate;
}
