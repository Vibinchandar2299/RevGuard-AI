package com.recoverai.service;

import com.recoverai.dto.BatchFunnelMetrics;
import com.recoverai.dto.BatchResponse;
import com.recoverai.dto.BatchRunRequest;
import com.recoverai.dto.PolicyDecision;
import com.recoverai.entity.*;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BatchService {

    private final RecoveryBatchRepository batchRepository;
    private final PaymentEventRepository paymentEventRepository;
    private final ClassificationRepository classificationRepository;
    private final RecoveryActionRepository actionRepository;
    private final RetryAttemptRepository retryAttemptRepository;
    private final AuditLogRepository auditLogRepository;
    private final PolicyEngine policyEngine;
    private final RecoveryExecutionService executionService;

    /**
     * Calculates stage-by-stage funnel metrics for a given batch.
     */
    @Transactional(readOnly = true)
    public BatchFunnelMetrics calculateFunnelMetrics(UUID batchId) {
        List<PaymentEvent> events = paymentEventRepository.findByBatchId(batchId);
        return computeFunnelMetricsFromEvents(events);
    }

    /**
     * Computes money-weighted recovery rate and funnel metrics for a collection of payment events.
     */
    public BatchFunnelMetrics computeFunnelMetricsFromEvents(List<PaymentEvent> events) {
        int totalEvents = events.size();
        BigDecimal atRiskAmount = BigDecimal.ZERO;
        int diagnosedEvents = 0;
        BigDecimal diagnosedAmount = BigDecimal.ZERO;
        int policyApprovedEvents = 0;
        BigDecimal policyInterventionAmount = BigDecimal.ZERO;
        int retryExecutedEvents = 0;
        int recoveredEvents = 0;
        BigDecimal recoveredAmount = BigDecimal.ZERO;
        int failedEvents = 0;
        int pendingHumanReviewEvents = 0;

        for (PaymentEvent event : events) {
            BigDecimal amount = event.getAmount() != null ? event.getAmount() : BigDecimal.ZERO;
            atRiskAmount = atRiskAmount.add(amount);

            // Diagnosed check
            boolean isDiagnosed = classificationRepository.existsByPaymentEventId(event.getId());
            if (isDiagnosed) {
                diagnosedEvents++;
                diagnosedAmount = diagnosedAmount.add(amount);
            }

            // Policy approved check
            List<RecoveryAction> actions = actionRepository.findByPaymentEventId(event.getId());
            boolean hasApprovedAction = actions.stream()
                    .anyMatch(a -> "RETRY".equalsIgnoreCase(a.getActionType())
                            || "SCHEDULE_RETRY".equalsIgnoreCase(a.getActionType())
                            || "EXECUTE_RETRY".equalsIgnoreCase(a.getActionType())
                            || "REQUEST_UPDATE".equalsIgnoreCase(a.getActionType())
                            || "DRAFT_MESSAGE".equalsIgnoreCase(a.getActionType()));
            if (hasApprovedAction) {
                policyApprovedEvents++;
                policyInterventionAmount = policyInterventionAmount.add(amount);
            }

            // Retry executed check
            int attemptsCount = retryAttemptRepository.countByPaymentEventId(event.getId());
            if (attemptsCount > 0) {
                retryExecutedEvents++;
            }

            // Status checks
            if (PaymentStatus.RECOVERED.name().equalsIgnoreCase(event.getStatus())) {
                recoveredEvents++;
                recoveredAmount = recoveredAmount.add(amount);
            } else if (PaymentStatus.FAILED.name().equalsIgnoreCase(event.getStatus())) {
                failedEvents++;
            } else if (PaymentStatus.ESCALATED.name().equalsIgnoreCase(event.getStatus())) {
                pendingHumanReviewEvents++;
            }
        }

        // Money-weighted recovery rate calculation
        BigDecimal recoveryRate = BigDecimal.ZERO;
        if (atRiskAmount.compareTo(BigDecimal.ZERO) > 0) {
            recoveryRate = recoveredAmount
                    .divide(atRiskAmount, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        return BatchFunnelMetrics.builder()
                .totalEvents(totalEvents)
                .atRiskAmount(atRiskAmount.setScale(2, RoundingMode.HALF_UP))
                .diagnosedEvents(diagnosedEvents)
                .diagnosedAmount(diagnosedAmount.setScale(2, RoundingMode.HALF_UP))
                .policyApprovedEvents(policyApprovedEvents)
                .policyInterventionAmount(policyInterventionAmount.setScale(2, RoundingMode.HALF_UP))
                .retryExecutedEvents(retryExecutedEvents)
                .recoveredEvents(recoveredEvents)
                .recoveredAmount(recoveredAmount.setScale(2, RoundingMode.HALF_UP))
                .failedEvents(failedEvents)
                .pendingHumanReviewEvents(pendingHumanReviewEvents)
                .recoveryRate(recoveryRate)
                .build();
    }

    /**
     * Recalculates and persists updated metrics for an existing batch.
     */
    @Transactional
    public RecoveryBatch recalculateAndSaveBatch(UUID batchId) {
        RecoveryBatch batch = batchRepository.findById(batchId)
                .orElseThrow(() -> new IllegalArgumentException("RecoveryBatch not found: " + batchId));

        BatchFunnelMetrics funnel = calculateFunnelMetrics(batchId);

        batch.setTotalEvents(funnel.getTotalEvents());
        batch.setAtRiskAmount(funnel.getAtRiskAmount());
        batch.setDiagnosedAmount(funnel.getDiagnosedAmount());
        batch.setInterventionAmount(funnel.getPolicyInterventionAmount());
        batch.setRecoveredAmount(funnel.getRecoveredAmount());
        batch.setRecoveryRate(funnel.getRecoveryRate());

        return batchRepository.save(batch);
    }

    /**
     * Retrieves batch details along with stage-by-stage funnel metrics.
     */
    @Transactional(readOnly = true)
    public BatchResponse getBatchResponse(UUID batchId) {
        RecoveryBatch batch = batchRepository.findById(batchId)
                .orElseThrow(() -> new IllegalArgumentException("RecoveryBatch not found: " + batchId));

        BatchFunnelMetrics funnel = calculateFunnelMetrics(batchId);
        return mapToResponse(batch, funnel);
    }

    /**
     * Lists all recovery batches.
     */
    @Transactional(readOnly = true)
    public List<BatchResponse> getAllBatches() {
        return batchRepository.findAll().stream()
                .map(b -> mapToResponse(b, calculateFunnelMetrics(b.getId())))
                .collect(Collectors.toList());
    }

    /**
     * Executes the recovery pipeline over a batch:
     * Deterministic Policy Evaluation -> Scheduled/Immediate Retry Execution -> Funnel Recalculation.
     */
    @Transactional
    public BatchResponse runRecoveryPipeline(BatchRunRequest request) {
        log.info("[STAGE 5: BATCH METRICS] Initiating recovery pipeline run for request: {}", request.getBatchName());

        RecoveryBatch batch;
        if (request.getBatchId() != null) {
            batch = batchRepository.findById(request.getBatchId())
                    .orElseThrow(() -> new IllegalArgumentException("Batch not found: " + request.getBatchId()));
        } else {
            String batchName = request.getBatchName() != null && !request.getBatchName().isBlank()
                    ? request.getBatchName()
                    : "BATCH-" + System.currentTimeMillis();

            batch = batchRepository.save(RecoveryBatch.builder()
                    .batchName(batchName)
                    .status("PROCESSING")
                    .build());
        }

        List<PaymentEvent> events;
        if (request.getEventIds() != null && !request.getEventIds().isEmpty()) {
            events = request.getEventIds().stream()
                    .map(paymentEventRepository::findByEventId)
                    .filter(Optional::isPresent)
                    .map(Optional::get)
                    .peek(e -> e.setBatch(batch))
                    .collect(Collectors.toList());
            paymentEventRepository.saveAll(events);
        } else {
            events = paymentEventRepository.findByBatchId(batch.getId());
        }

        log.info("[STAGE 5: BATCH METRICS] Batch {} has {} events to process", batch.getBatchName(), events.size());

        boolean executeRetries = Boolean.TRUE.equals(request.getExecuteRetries());

        for (PaymentEvent event : events) {
            // Stage 2 fallback: create classification if missing
            Classification classification = classificationRepository.findByPaymentEventId(event.getId())
                    .orElseGet(() -> {
                        Classification c = Classification.builder()
                                .paymentEvent(event)
                                .reasonCode(event.getRawFailureCode() != null ? event.getRawFailureCode().toLowerCase() : "other")
                                .confidence(new BigDecimal("0.95"))
                                .suggestedAction("SCHEDULE_RETRY")
                                .modelName("llama-3.3-70b-versatile")
                                .build();
                        return classificationRepository.save(c);
                    });

            // Stage 3: Deterministic Policy Evaluation
            PolicyDecision decision = policyEngine.evaluate(event, classification);

            // Stage 4: If policy approved retry and executeRetries is requested, trigger attempt 1
            if (executeRetries && decision.getActionType() == com.recoverai.model.enums.ActionType.RETRY) {
                if (retryAttemptRepository.countByPaymentEventId(event.getId()) == 0) {
                    executionService.executeRetry(event, 1);
                }
            }
        }

        // Recalculate metrics
        BatchFunnelMetrics funnel = computeFunnelMetricsFromEvents(paymentEventRepository.findByBatchId(batch.getId()));

        batch.setStatus("COMPLETED");
        batch.setCompletedAt(OffsetDateTime.now());
        batch.setTotalEvents(funnel.getTotalEvents());
        batch.setAtRiskAmount(funnel.getAtRiskAmount());
        batch.setDiagnosedAmount(funnel.getDiagnosedAmount());
        batch.setInterventionAmount(funnel.getPolicyInterventionAmount());
        batch.setRecoveredAmount(funnel.getRecoveredAmount());
        batch.setRecoveryRate(funnel.getRecoveryRate());
        RecoveryBatch savedBatch = batchRepository.save(batch);

        log.info("[STAGE 5: BATCH METRICS] Batch {} finished. Recovery rate: {}% (Rs {} of Rs {})",
                savedBatch.getBatchName(), savedBatch.getRecoveryRate(),
                savedBatch.getRecoveredAmount(), savedBatch.getAtRiskAmount());

        return mapToResponse(savedBatch, funnel);
    }

    private BatchResponse mapToResponse(RecoveryBatch b, BatchFunnelMetrics funnel) {
        return BatchResponse.builder()
                .id(b.getId())
                .batchName(b.getBatchName())
                .status(b.getStatus())
                .totalEvents(b.getTotalEvents())
                .atRiskAmount(b.getAtRiskAmount())
                .diagnosedAmount(b.getDiagnosedAmount())
                .interventionAmount(b.getInterventionAmount())
                .recoveredAmount(b.getRecoveredAmount())
                .recoveryRate(b.getRecoveryRate())
                .createdAt(b.getCreatedAt())
                .completedAt(b.getCompletedAt())
                .funnelMetrics(funnel)
                .build();
    }
}
