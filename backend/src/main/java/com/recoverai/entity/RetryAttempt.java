package com.recoverai.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "retry_attempts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RetryAttempt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_event_id", nullable = false)
    private PaymentEvent paymentEvent;

    @Column(name = "attempt_number", nullable = false)
    private Integer attemptNumber;

    @Column(name = "executor_type", nullable = false)
    private String executorType;

    @Column(nullable = false)
    private String status;

    @Column(name = "gateway_reference_id")
    private String gatewayReferenceId;

    @Column(name = "error_message")
    private String errorMessage;

    @Column(name = "attempted_at", nullable = false, updatable = false)
    private OffsetDateTime attemptedAt;

    @PrePersist
    protected void onCreate() {
        if (attemptedAt == null) {
            attemptedAt = OffsetDateTime.now();
        }
    }
}
