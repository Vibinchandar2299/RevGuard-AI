package com.recoverai.controller;

import com.recoverai.dto.IngestionResponse;
import com.recoverai.dto.PaymentIngestionRequest;
import com.recoverai.service.IngestionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class IngestionController {

    private final IngestionService ingestionService;

    @PostMapping("/ingest")
    public ResponseEntity<IngestionResponse> ingestEvent(@Valid @RequestBody PaymentIngestionRequest request) {
        IngestionResponse response = ingestionService.ingestEvent(request);
        return ResponseEntity.ok(response);
    }
}
