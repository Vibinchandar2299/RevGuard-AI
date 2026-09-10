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
public class AuditFeedItemResponse {
    private UUID id;
    private String eventId;
    private String actor;
    private String action;
    private String reason;
    private OffsetDateTime createdAt;
}
