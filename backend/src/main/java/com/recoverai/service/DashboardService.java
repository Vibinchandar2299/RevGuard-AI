package com.recoverai.service;

import com.recoverai.dto.AuditFeedItemResponse;
import com.recoverai.dto.DashboardSummaryResponse;
import com.recoverai.dto.ReasonBreakdownResponse;
import com.recoverai.entity.AuditLog;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DashboardService {

    private final PaymentEventRepository paymentEventRepository;
    private final RecoveryPolicyRepository policyRepository;
    private final RecoveryMessageRepository messageRepository;
    private final AuditLogRepository auditLogRepository;
    private final ClassificationRepository classificationRepository;

    /**
     * Aggregates high-level executive dashboard metrics.
     */
    @Transactional(readOnly = true)
    public DashboardSummaryResponse getDashboardSummary() {
        List<PaymentEvent> allEvents = paymentEventRepository.findAll();

        BigDecimal totalAtRisk = BigDecimal.ZERO;
        BigDecimal totalRecovered = BigDecimal.ZERO;
        int recoveredCount = 0;
        int failedCount = 0;
        int escalatedCount = 0;

        for (PaymentEvent event : allEvents) {
            BigDecimal amount = event.getAmount() != null ? event.getAmount() : BigDecimal.ZERO;
            totalAtRisk = totalAtRisk.add(amount);

            if (PaymentStatus.RECOVERED.name().equalsIgnoreCase(event.getStatus())) {
                totalRecovered = totalRecovered.add(amount);
                recoveredCount++;
            } else if (PaymentStatus.FAILED.name().equalsIgnoreCase(event.getStatus())) {
                failedCount++;
            } else if (PaymentStatus.ESCALATED.name().equalsIgnoreCase(event.getStatus())) {
                escalatedCount++;
            }
        }

        BigDecimal aggregateRecoveryRate = BigDecimal.ZERO;
        if (totalAtRisk.compareTo(BigDecimal.ZERO) > 0) {
            aggregateRecoveryRate = totalRecovered
                    .divide(totalAtRisk, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        int activePolicies = (int) policyRepository.countByActiveTrue();
        int pendingDrafts = messageRepository.findByStatus("DRAFTED").size();
        int pendingReviews = escalatedCount + pendingDrafts;

        return DashboardSummaryResponse.builder()
                .totalAtRiskAmount(totalAtRisk.setScale(2, RoundingMode.HALF_UP))
                .totalRecoveredAmount(totalRecovered.setScale(2, RoundingMode.HALF_UP))
                .aggregateRecoveryRate(aggregateRecoveryRate)
                .totalEvents(allEvents.size())
                .recoveredEventsCount(recoveredCount)
                .failedEventsCount(failedCount)
                .activePoliciesCount(activePolicies)
                .pendingHumanReviewsCount(pendingReviews)
                .build();
    }

    /**
     * Computes breakdown of payment failures, at-risk volume, and recovery rate grouped by failure reason.
     */
    @Transactional(readOnly = true)
    public List<ReasonBreakdownResponse> getReasonBreakdown() {
        List<PaymentEvent> allEvents = paymentEventRepository.findAll();
        Map<UUID, String> classificationMap = classificationRepository.findAll().stream()
                .filter(c -> c.getPaymentEvent() != null)
                .collect(Collectors.toMap(c -> c.getPaymentEvent().getId(), c -> c.getReasonCode(), (a, b) -> a));

        Map<String, List<PaymentEvent>> grouped = allEvents.stream()
                .collect(Collectors.groupingBy(e -> {
                    String reason = classificationMap.get(e.getId());
                    if (reason != null && !reason.isBlank()) {
                        return reason.toLowerCase();
                    }
                    return normalizeReasonCode(e.getRawFailureCode());
                }));

        List<ReasonBreakdownResponse> results = new ArrayList<>();

        for (Map.Entry<String, List<PaymentEvent>> entry : grouped.entrySet()) {
            String reason = entry.getKey();
            List<PaymentEvent> events = entry.getValue();

            BigDecimal atRisk = BigDecimal.ZERO;
            BigDecimal recovered = BigDecimal.ZERO;
            int recoveredEvents = 0;

            for (PaymentEvent e : events) {
                BigDecimal amt = e.getAmount() != null ? e.getAmount() : BigDecimal.ZERO;
                atRisk = atRisk.add(amt);
                if (PaymentStatus.RECOVERED.name().equalsIgnoreCase(e.getStatus())) {
                    recovered = recovered.add(amt);
                    recoveredEvents++;
                }
            }

            BigDecimal rate = BigDecimal.ZERO;
            if (atRisk.compareTo(BigDecimal.ZERO) > 0) {
                rate = recovered
                        .divide(atRisk, 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .setScale(2, RoundingMode.HALF_UP);
            }

            double successRate = events.isEmpty() ? 0.0 : ((double) recoveredEvents / events.size()) * 100.0;

            results.add(ReasonBreakdownResponse.builder()
                    .reasonCode(reason)
                    .reasonDescription(describeReason(reason))
                    .count(events.size())
                    .atRiskAmount(atRisk.setScale(2, RoundingMode.HALF_UP))
                    .recoveredAmount(recovered.setScale(2, RoundingMode.HALF_UP))
                    .recoveryRate(rate)
                    .successRate(Math.round(successRate * 100.0) / 100.0)
                    .build());
        }

        // Sort by atRiskAmount descending
        results.sort(Comparator.comparing(ReasonBreakdownResponse::getAtRiskAmount).reversed());
        return results;
    }

    /**
     * Retrieves recent chronological audit log feed.
     */
    @Transactional(readOnly = true)
    public List<AuditFeedItemResponse> getRecentAuditFeed(int limit) {
        List<AuditLog> logs = auditLogRepository.findTop50ByOrderByCreatedAtDesc();
        return logs.stream()
                .limit(limit > 0 ? limit : 50)
                .map(l -> AuditFeedItemResponse.builder()
                        .id(l.getId())
                        .eventId(l.getPaymentEvent() != null ? l.getPaymentEvent().getEventId() : null)
                        .actor(l.getActor())
                        .action(l.getAction())
                        .reason(l.getReason())
                        .createdAt(l.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }

    private String normalizeReasonCode(String rawCode) {
        if (rawCode == null) return "other";
        String lower = rawCode.toLowerCase();
        if (lower.contains("insufficient") || lower.contains("fund")) return "insufficient_funds";
        if (lower.contains("timeout") || lower.contains("network")) return "network_timeout";
        if (lower.contains("bank") || (lower.contains("decline") && !lower.contains("risk"))) return "bank_declined";
        if (lower.contains("expired")) return "card_expired";
        if (lower.contains("fraud") || lower.contains("high_risk") || lower.contains("risk")) return "fraud_suspected";
        return "other";
    }

    private String describeReason(String reason) {
        switch (reason) {
            case "insufficient_funds":
                return "Insufficient cardholder account balance";
            case "network_timeout":
                return "Acquirer/issuer gateway communication timeout";
            case "bank_declined":
                return "Issuing bank authorization policy rejection";
            case "card_expired":
                return "Payment card expired beyond validity date";
            case "fraud_suspected":
                return "Risk/AML heuristic rule trigger";
            default:
                return "Unclassified payment processing exception";
        }
    }
}
