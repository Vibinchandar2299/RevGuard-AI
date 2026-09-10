package com.recoverai.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "classifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Classification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_event_id", nullable = false, unique = true)
    private PaymentEvent paymentEvent;

    @Column(name = "reason_code", nullable = false)
    private String reasonCode;

    @Column(nullable = false, precision = 5, scale = 4)
    private BigDecimal confidence;

    @Column(name = "suggested_action", nullable = false)
    private String suggestedAction;

    @Column(name = "model_name", nullable = false)
    @Builder.Default
    private String modelName = "llama-3.3-70b-versatile";

    @Column(name = "raw_response")
    private String rawResponse;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }
}
