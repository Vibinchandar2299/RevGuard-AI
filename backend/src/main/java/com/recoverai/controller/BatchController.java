package com.recoverai.controller;

import com.recoverai.dto.BatchFunnelMetrics;
import com.recoverai.dto.BatchResponse;
import com.recoverai.dto.BatchRunRequest;
import com.recoverai.service.BatchService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/batches")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class BatchController {

    private final BatchService batchService;

    @PostMapping("/run")
    public ResponseEntity<BatchResponse> runBatch(@RequestBody(required = false) BatchRunRequest request) {
        if (request == null) {
            request = BatchRunRequest.builder().build();
        }
        log.info("[REST API] Triggering recovery batch run: {}", request.getBatchName());
        BatchResponse response = batchService.runRecoveryPipeline(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<List<BatchResponse>> getAllBatches() {
        return ResponseEntity.ok(batchService.getAllBatches());
    }

    @GetMapping("/{id}")
    public ResponseEntity<BatchResponse> getBatchById(@PathVariable UUID id) {
        return ResponseEntity.ok(batchService.getBatchResponse(id));
    }

    @GetMapping("/{id}/funnel")
    public ResponseEntity<BatchFunnelMetrics> getBatchFunnel(@PathVariable UUID id) {
        return ResponseEntity.ok(batchService.calculateFunnelMetrics(id));
    }
}
