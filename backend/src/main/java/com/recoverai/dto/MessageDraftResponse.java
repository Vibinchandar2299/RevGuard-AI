package com.recoverai.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MessageDraftResponse {
    private UUID id;
    private String eventId;
    private UUID paymentEventId;
    private String customerName;
    private String customerEmail;
    private String channel;
    private String subject;
    private String body;
    private String status;
    private OffsetDateTime createdAt;
    private OffsetDateTime sentAt;
}
