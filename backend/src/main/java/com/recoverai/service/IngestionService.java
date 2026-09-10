package com.recoverai.service;

import com.recoverai.dto.IngestionResponse;
import com.recoverai.dto.PaymentIngestionRequest;
import com.recoverai.entity.AuditLog;
import com.recoverai.entity.Customer;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.entity.RecoveryBatch;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.AuditLogRepository;
import com.recoverai.repository.CustomerRepository;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.repository.RecoveryBatchRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.OffsetDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class IngestionService {

    private final PaymentEventRepository paymentEventRepository;
    private final CustomerRepository customerRepository;
    private final RecoveryBatchRepository batchRepository;
    private final AuditLogRepository auditLogRepository;
    private final TransactionTemplate transactionTemplate;

    /**
     * Stage 1: Detection & Ingestion Layer.
     * Deterministic, idempotent ingestion of failed payment events.
     * Strictly dedupes on event_id via DB unique constraint; returns a clean
     * "ALREADY_PROCESSED" response with no duplicate records or side effects.
     */
    public IngestionResponse ingestEvent(PaymentIngestionRequest request) {
        log.info("[STAGE 1: INGESTION] Processing payment failure event: {}", request.getEventId());

        // Fast-path idempotency check: query DB for existing event
        Optional<PaymentEvent> existingOpt = paymentEventRepository.findByEventId(request.getEventId());
        if (existingOpt.isPresent()) {
            log.info("[STAGE 1: INGESTION] Duplicate event detected for event_id: {}. Returning ALREADY_PROCESSED.", request.getEventId());
            return buildAlreadyProcessedResponse(existingOpt.get());
        }

        try {
            return transactionTemplate.execute(status -> {
                // Double check inside transaction boundary
                Optional<PaymentEvent> innerExisting = paymentEventRepository.findByEventId(request.getEventId());
                if (innerExisting.isPresent()) {
                    return buildAlreadyProcessedResponse(innerExisting.get());
                }

                // Resolve or create customer
                Customer customer = resolveCustomer(request);

                // Resolve recovery batch if provided
                RecoveryBatch batch = null;
                if (request.getBatchId() != null) {
                    batch = batchRepository.findById(request.getBatchId()).orElse(null);
                }

                // Create and persist payment event
                PaymentEvent event = PaymentEvent.builder()
                        .eventId(request.getEventId())
                        .customer(customer)
                        .batch(batch)
                        .amount(request.getAmount())
                        .currency(request.getCurrency() != null ? request.getCurrency() : "INR")
                        .paymentMethod(request.getPaymentMethod() != null ? request.getPaymentMethod() : "CARD")
                        .rawFailureCode(request.getRawFailureCode())
                        .rawFailureMessage(request.getRawFailureMessage())
                        .status(PaymentStatus.INGESTED.name())
                        .build();

                PaymentEvent savedEvent = paymentEventRepository.saveAndFlush(event);

                // Audit log for deterministic ingestion
                AuditLog audit = AuditLog.builder()
                        .paymentEvent(savedEvent)
                        .actor(AuditActor.SYSTEM.name())
                        .action("PAYMENT_INGESTED")
                        .reason("Payment failure event received and validated for customer: " + customer.getEmail())
                        .build();
                auditLogRepository.save(audit);

                log.info("[STAGE 1: INGESTION] Successfully ingested event: {} (amount: Rs {})", savedEvent.getEventId(), savedEvent.getAmount());

                return IngestionResponse.builder()
                        .eventId(savedEvent.getEventId())
                        .paymentEventId(savedEvent.getId())
                        .status("INGESTED")
                        .duplicate(false)
                        .message("Payment failure event ingested successfully")
                        .timestamp(savedEvent.getCreatedAt())
                        .build();
            });

        } catch (DataIntegrityViolationException ex) {
            // Concurrent race condition handler: if a duplicate arrived concurrently,
            // the database uk_payment_events_event_id unique constraint guarantees deduplication.
            log.warn("[STAGE 1: INGESTION] Caught unique constraint violation for event_id: {}. Resolving as duplicate.", request.getEventId());
            PaymentEvent existing = paymentEventRepository.findByEventId(request.getEventId()).orElse(null);
            if (existing != null) {
                return buildAlreadyProcessedResponse(existing);
            }

            return IngestionResponse.builder()
                    .eventId(request.getEventId())
                    .status("ALREADY_PROCESSED")
                    .duplicate(true)
                    .message("Payment event already processed with id: " + request.getEventId())
                    .timestamp(OffsetDateTime.now())
                    .build();
        }
    }

    private IngestionResponse buildAlreadyProcessedResponse(PaymentEvent event) {
        return IngestionResponse.builder()
                .eventId(event.getEventId())
                .paymentEventId(event.getId())
                .status("ALREADY_PROCESSED")
                .duplicate(true)
                .message("Payment event already processed with id: " + event.getEventId())
                .timestamp(OffsetDateTime.now())
                .build();
    }

    private Customer resolveCustomer(PaymentIngestionRequest request) {
        if (request.getExternalCustomerId() != null && !request.getExternalCustomerId().isBlank()) {
            Optional<Customer> byExtId = customerRepository.findByExternalCustomerId(request.getExternalCustomerId());
            if (byExtId.isPresent()) {
                return byExtId.get();
            }
        }

        return customerRepository.findByEmail(request.getCustomerEmail())
                .orElseGet(() -> customerRepository.save(
                        Customer.builder()
                                .externalCustomerId(request.getExternalCustomerId())
                                .name(request.getCustomerName())
                                .email(request.getCustomerEmail())
                                .phone(request.getCustomerPhone())
                                .build()
                ));
    }
}
