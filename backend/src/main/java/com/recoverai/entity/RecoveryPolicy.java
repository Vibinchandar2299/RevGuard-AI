package com.recoverai.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "recovery_policies")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecoveryPolicy {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "reason_code", nullable = false)
    private String reasonCode;

    @Column(nullable = false)
    @Builder.Default
    private Integer version = 1;

    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    @Column(name = "min_confidence", nullable = false, precision = 5, scale = 4)
    @Builder.Default
    private BigDecimal minConfidence = new BigDecimal("0.6000");

    @Column(nullable = false)
    private String action;

    @Column(name = "max_attempts", nullable = false)
    @Builder.Default
    private Integer maxAttempts = 0;

    @Column(name = "cooldown_seconds", nullable = false)
    @Builder.Default
    private Integer cooldownSeconds = 0;

    @Column(name = "amount_cap", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal amountCap = new BigDecimal("20000.00");

    @Column(name = "escalate_after_attempts", nullable = false)
    @Builder.Default
    private Integer escalateAfterAttempts = 0;

    private String description;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = OffsetDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
