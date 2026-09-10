package com.recoverai.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchRunRequest {
    private String batchName;
    private UUID batchId;
    private List<String> eventIds;
    private Boolean executeRetries;
}
