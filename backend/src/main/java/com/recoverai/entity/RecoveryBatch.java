package com.recoverai.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "recovery_batches")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecoveryBatch {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "batch_name", nullable = false)
    private String batchName;

    @Column(nullable = false)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "total_events", nullable = false)
    @Builder.Default
    private Integer totalEvents = 0;

    @Column(name = "at_risk_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal atRiskAmount = BigDecimal.ZERO;

    @Column(name = "diagnosed_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal diagnosedAmount = BigDecimal.ZERO;

    @Column(name = "intervention_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal interventionAmount = BigDecimal.ZERO;

    @Column(name = "recovered_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal recoveredAmount = BigDecimal.ZERO;

    @Column(name = "recovery_rate", nullable = false, precision = 7, scale = 2)
    @Builder.Default
    private BigDecimal recoveryRate = BigDecimal.ZERO;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }
}
