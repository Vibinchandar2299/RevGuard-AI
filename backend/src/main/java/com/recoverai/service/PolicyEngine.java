package com.recoverai.service;

import com.recoverai.config.RecoveryProperties;
import com.recoverai.dto.PolicyDecision;
import com.recoverai.entity.AuditLog;
import com.recoverai.entity.Classification;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.entity.RecoveryAction;
import com.recoverai.entity.RecoveryPolicy;
import com.recoverai.model.enums.ActionType;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.AuditLogRepository;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.repository.RecoveryActionRepository;
import com.recoverai.repository.RecoveryPolicyRepository;
import com.recoverai.repository.RetryAttemptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Stage 3: Policy & Risk Decision Engine.
 * Purely deterministic Java engine.
 * Consults the data-driven, versioned intervention matrix from the recovery_policies table (WHERE active = true).
 * Strictly enforces:
 *  1. Zero-confidence safety block (LLM unavailable/unparseable routes to human review, zero autonomous action)
 *  2. Minimum confidence threshold per reason code
 *  3. Autonomous amount cap (Rs 20,000)
 *  4. Retry-count limit handling
 *  5. Active policy version capture on recovery_actions
 *  6. Audit logging with actor=POLICY_ENGINE
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PolicyEngine {

    private final RecoveryPolicyRepository policyRepository;
    private final RecoveryActionRepository actionRepository;
    private final RetryAttemptRepository retryAttemptRepository;
    private final AuditLogRepository auditLogRepository;
    private final PaymentEventRepository paymentEventRepository;
    private final RecoveryProperties recoveryProperties;

    @Transactional
    public PolicyDecision evaluate(PaymentEvent event, Classification classification) {
        log.info("[STAGE 3: POLICY ENGINE] Evaluating event: {} (amount: Rs {})", event.getEventId(), event.getAmount());

        // SAFETY RULE 1: Zero-Confidence Safety Block
        // If Groq is unavailable, times out, or returns unparseable output (confidence=0 or null),
        // the Policy Engine MUST block any autonomous action and route to human review.
        if (classification == null || classification.getConfidence() == null || classification.getConfidence().compareTo(BigDecimal.ZERO) <= 0) {
            log.warn("[STAGE 3: POLICY ENGINE] Zero confidence detected for event: {}. Triggering safety block.", event.getEventId());
            RecoveryPolicy fallbackPolicy = getActivePolicyOrFallback("other");
            return recordDecision(
                    event,
                    ActionType.ESCALATE,
                    fallbackPolicy.getVersion(),
                    fallbackPolicy.getReasonCode(),
                    "Zero-confidence safety block: LLM diagnosis unavailable or zero-confidence (confidence=0.0); autonomous action strictly blocked and routed to human review",
                    null,
                    0,
                    fallbackPolicy.getMaxAttempts(),
                    PaymentStatus.ESCALATED
            );
        }

        // Fetch active policy dynamically from recovery_policies table (DO NOT hardcode matrix in Java)
        String reasonCode = classification.getReasonCode();
        RecoveryPolicy policy = getActivePolicyOrFallback(reasonCode);
        log.debug("[STAGE 3: POLICY ENGINE] Resolved active policy for '{}': version={}, action={}, minConf={}, maxAttempts={}, cap={}",
                reasonCode, policy.getVersion(), policy.getAction(), policy.getMinConfidence(), policy.getMaxAttempts(), policy.getAmountCap());

        // SAFETY RULE 2: Minimum Confidence Threshold Check
        if (classification.getConfidence().compareTo(policy.getMinConfidence()) < 0) {
            log.warn("[STAGE 3: POLICY ENGINE] Event {} confidence {} is below required threshold {} for policy '{}'",
                    event.getEventId(), classification.getConfidence(), policy.getMinConfidence(), policy.getReasonCode());
            return recordDecision(
                    event,
                    ActionType.ESCALATE,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Confidence threshold breach: diagnosis confidence %.4f is below minimum required %.4f for policy '%s'; escalated to human review",
                            classification.getConfidence(), policy.getMinConfidence(), policy.getReasonCode()),
                    null,
                    policy.getCooldownSeconds(),
                    policy.getMaxAttempts(),
                    PaymentStatus.ESCALATED
            );
        }

        // SAFETY RULE 3: Rs 20,000 Autonomous Amount Cap
        BigDecimal amountCap = policy.getAmountCap() != null ? policy.getAmountCap() : recoveryProperties.getAutonomousAmountCap();
        if (event.getAmount().compareTo(amountCap) > 0) {
            log.warn("[STAGE 3: POLICY ENGINE] Event {} amount Rs {} exceeds autonomous cap Rs {}",
                    event.getEventId(), event.getAmount(), amountCap);
            return recordDecision(
                    event,
                    ActionType.ESCALATE,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Autonomous amount cap exceeded: event amount Rs %.2f exceeds policy cap Rs %.2f; routed to human review",
                            event.getAmount(), amountCap),
                    null,
                    0,
                    policy.getMaxAttempts(),
                    PaymentStatus.ESCALATED
            );
        }

        // RULE 4: Retry Count Handling
        int existingAttempts = retryAttemptRepository.countByPaymentEventId(event.getId());
        if (policy.getMaxAttempts() != null && policy.getMaxAttempts() > 0 && existingAttempts >= policy.getMaxAttempts()) {
            log.warn("[STAGE 3: POLICY ENGINE] Event {} retry count {} has reached or exceeded max attempts {}",
                    event.getEventId(), existingAttempts, policy.getMaxAttempts());
            return recordDecision(
                    event,
                    ActionType.ESCALATE,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Retry count exceeded: event has %d attempts which reaches or exceeds policy max %d attempts; escalated to human review",
                            existingAttempts, policy.getMaxAttempts()),
                    null,
                    0,
                    policy.getMaxAttempts(),
                    PaymentStatus.ESCALATED
            );
        }

        // RULE 5: Execute Policy Action according to intervention matrix
        ActionType policyAction = ActionType.fromValue(policy.getAction());
        return switch (policyAction) {
            case RETRY -> recordDecision(
                    event,
                    ActionType.RETRY,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Policy v%d authorized autonomous RETRY for '%s' (attempt %d/%d, amount Rs %.2f, cooldown %ds)",
                            policy.getVersion(), policy.getReasonCode(), existingAttempts + 1, policy.getMaxAttempts(), event.getAmount(), policy.getCooldownSeconds()),
                    event.getAmount(),
                    policy.getCooldownSeconds(),
                    policy.getMaxAttempts(),
                    PaymentStatus.RETRY_SCHEDULED
            );
            case REQUEST_UPDATE -> recordDecision(
                    event,
                    ActionType.REQUEST_UPDATE,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Policy v%d determined REQUEST_UPDATE for '%s': customer must provide updated payment details",
                            policy.getVersion(), policy.getReasonCode()),
                    null,
                    0,
                    0,
                    PaymentStatus.ACTIONED
            );
            case BLOCK -> recordDecision(
                    event,
                    ActionType.BLOCK,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Policy v%d strictly BLOCKED autonomous recovery for '%s': suspected fraud or high risk",
                            policy.getVersion(), policy.getReasonCode()),
                    null,
                    0,
                    0,
                    PaymentStatus.BLOCKED
            );
            case ESCALATE -> recordDecision(
                    event,
                    ActionType.ESCALATE,
                    policy.getVersion(),
                    policy.getReasonCode(),
                    String.format("Policy v%d ESCALATED '%s' directly to human review",
                            policy.getVersion(), policy.getReasonCode()),
                    null,
                    0,
                    0,
                    PaymentStatus.ESCALATED
            );
        };
    }

    private RecoveryPolicy getActivePolicyOrFallback(String reasonCode) {
        if (reasonCode != null) {
            Optional<RecoveryPolicy> policyOpt = policyRepository.findByReasonCodeAndActiveTrue(reasonCode.trim().toLowerCase());
            if (policyOpt.isPresent()) {
                return policyOpt.get();
            }
        }

        return policyRepository.findByReasonCodeAndActiveTrue("other")
                .orElseGet(() -> RecoveryPolicy.builder()
                        .reasonCode("other")
                        .version(1)
                        .active(true)
                        .minConfidence(BigDecimal.ZERO)
                        .action(ActionType.ESCALATE.name())
                        .maxAttempts(0)
                        .cooldownSeconds(0)
                        .amountCap(recoveryProperties.getAutonomousAmountCap())
                        .escalateAfterAttempts(0)
                        .description("Default fallback policy")
                        .build()
                );
    }

    private PolicyDecision recordDecision(
            PaymentEvent event,
            ActionType actionType,
            Integer policyVersion,
            String policyReasonCode,
            String decisionReason,
            BigDecimal authorizedAmount,
            Integer cooldownSeconds,
            Integer maxAttempts,
            PaymentStatus targetStatus
    ) {
        // 1. Persist RecoveryAction record
        RecoveryAction action = RecoveryAction.builder()
                .paymentEvent(event)
                .actionType(actionType.name())
                .policyVersion(policyVersion != null ? policyVersion : 1)
                .policyReasonCode(policyReasonCode)
                .decisionReason(decisionReason)
                .authorizedAmount(authorizedAmount)
                .status("PENDING")
                .build();
        RecoveryAction savedAction = actionRepository.save(action);

        // 2. Persist AuditLog record with actor=POLICY_ENGINE
        AuditLog audit = AuditLog.builder()
                .paymentEvent(event)
                .actor(AuditActor.POLICY_ENGINE.name())
                .action("ACTION_DECIDED")
                .reason(decisionReason)
                .build();
        auditLogRepository.save(audit);

        // 3. Update payment event status
        event.setStatus(targetStatus.name());
        paymentEventRepository.save(event);

        log.info("[STAGE 3: POLICY ENGINE] Decision recorded for event {}: action={}, policyVersion={}, status={}",
                event.getEventId(), actionType, policyVersion, targetStatus);

        return PolicyDecision.builder()
                .actionType(actionType)
                .policyVersion(policyVersion)
                .policyReasonCode(policyReasonCode)
                .decisionReason(decisionReason)
                .authorizedAmount(authorizedAmount)
                .cooldownSeconds(cooldownSeconds)
                .maxAttempts(maxAttempts)
                .recoveryAction(savedAction)
                .build();
    }
}
