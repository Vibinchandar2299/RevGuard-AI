package com.recoverai.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentIngestionRequest {

    @NotBlank(message = "eventId is required")
    private String eventId;

    @NotNull(message = "amount is required")
    @DecimalMin(value = "0.01", message = "amount must be greater than 0")
    private BigDecimal amount;

    @Builder.Default
    private String currency = "INR";

    @NotBlank(message = "customerEmail is required")
    @Email(message = "customerEmail must be a valid email address")
    private String customerEmail;

    @NotBlank(message = "customerName is required")
    private String customerName;

    private String customerPhone;

    private String externalCustomerId;

    @Builder.Default
    private String paymentMethod = "CARD";

    private String rawFailureCode;

    private String rawFailureMessage;

    private UUID batchId;
}
