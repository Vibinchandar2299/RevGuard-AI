package com.recoverai.dto;

import com.recoverai.entity.RecoveryAction;
import com.recoverai.model.enums.ActionType;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PolicyDecision {

    private ActionType actionType;
    private Integer policyVersion;
    private String policyReasonCode;
    private String decisionReason;
    private BigDecimal authorizedAmount;
    private Integer cooldownSeconds;
    private Integer maxAttempts;
    private RecoveryAction recoveryAction;
}
