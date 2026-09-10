package com.recoverai.dto;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IngestionResponse {

    private String eventId;
    private UUID paymentEventId;
    private String status; // "INGESTED" or "ALREADY_PROCESSED"
    private boolean duplicate;
    private String message;
    private OffsetDateTime timestamp;
}
