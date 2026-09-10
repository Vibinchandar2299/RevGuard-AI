package com.recoverai.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "recovery_actions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecoveryAction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_event_id", nullable = false)
    private PaymentEvent paymentEvent;

    @Column(name = "action_type", nullable = false)
    private String actionType;

    @Column(name = "policy_version", nullable = false)
    @Builder.Default
    private Integer policyVersion = 1;

    @Column(name = "policy_reason_code", nullable = false)
    private String policyReasonCode;

    @Column(name = "decision_reason", nullable = false)
    private String decisionReason;

    @Column(name = "authorized_amount", precision = 15, scale = 2)
    private BigDecimal authorizedAmount;

    @Column(nullable = false)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }
}
