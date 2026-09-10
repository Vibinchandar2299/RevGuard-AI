package com.recoverai.controller;

import com.recoverai.dto.IngestionResponse;
import com.recoverai.dto.PaymentIngestionRequest;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.service.IngestionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/simulate")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SimulationController {

    private final IngestionService ingestionService;
    private final PaymentEventRepository paymentEventRepository;

    /**
     * Reliability Proof: Simulates a new failed payment webhook.
     */
    @PostMapping("/failure")
    public ResponseEntity<IngestionResponse> simulateFailure(@RequestBody(required = false) Map<String, Object> body) {
        String eventId = body != null && body.containsKey("eventId")
                ? body.get("eventId").toString()
                : "evt_sim_" + UUID.randomUUID().toString().substring(0, 8);

        BigDecimal amount = body != null && body.containsKey("amount")
                ? new BigDecimal(body.get("amount").toString())
                : new BigDecimal("4500.00");

        String reasonCode = body != null && body.containsKey("rawFailureCode")
                ? body.get("rawFailureCode").toString()
                : "ERR_INSUFFICIENT_FUNDS";

        PaymentIngestionRequest request = PaymentIngestionRequest.builder()
                .eventId(eventId)
                .amount(amount)
                .currency("INR")
                .customerEmail("customer.sim@example.com")
                .customerName("Simulated Customer")
                .paymentMethod("CARD")
                .rawFailureCode(reasonCode)
                .rawFailureMessage("Simulated failure event: " + reasonCode)
                .build();

        return ResponseEntity.ok(ingestionService.ingestEvent(request));
    }

    /**
     * Reliability Proof: Simulates a duplicate webhook for an already ingested event.
     * Proves that RecoverAI handles duplicate webhooks strictly and idempotently.
     */
    @PostMapping("/duplicate")
    public ResponseEntity<IngestionResponse> simulateDuplicate(@RequestBody(required = false) Map<String, Object> body) {
        String targetEventId = null;

        if (body != null && body.containsKey("eventId")) {
            targetEventId = body.get("eventId").toString();
        } else {
            // Pick most recent event to replay
            List<PaymentEvent> recent = paymentEventRepository.findTop50ByOrderByCreatedAtDesc();
            if (!recent.isEmpty()) {
                targetEventId = recent.get(0).getEventId();
            } else {
                targetEventId = "evt_seed_001";
            }
        }

        PaymentEvent existing = paymentEventRepository.findByEventId(targetEventId)
                .orElse(null);

        PaymentIngestionRequest replayRequest;
        if (existing != null) {
            replayRequest = PaymentIngestionRequest.builder()
                    .eventId(existing.getEventId())
                    .amount(existing.getAmount())
                    .currency(existing.getCurrency())
                    .customerEmail(existing.getCustomer() != null ? existing.getCustomer().getEmail() : "customer@example.com")
                    .customerName(existing.getCustomer() != null ? existing.getCustomer().getName() : "Customer")
                    .paymentMethod(existing.getPaymentMethod())
                    .rawFailureCode(existing.getRawFailureCode())
                    .rawFailureMessage(existing.getRawFailureMessage())
                    .build();
        } else {
            replayRequest = PaymentIngestionRequest.builder()
                    .eventId(targetEventId)
                    .amount(new BigDecimal("1000.00"))
                    .customerEmail("replay@example.com")
                    .customerName("Replay Customer")
                    .build();
        }

        return ResponseEntity.ok(ingestionService.ingestEvent(replayRequest));
    }
}
