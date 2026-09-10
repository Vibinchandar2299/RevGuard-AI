package com.recoverai.service;

import com.recoverai.dto.ExecutionResult;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.entity.RecoveryPolicy;
import com.recoverai.entity.RetryAttempt;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.repository.RecoveryPolicyRepository;
import com.recoverai.repository.RetryAttemptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class SchedulerService {

    private final PaymentEventRepository paymentEventRepository;
    private final RecoveryPolicyRepository policyRepository;
    private final RetryAttemptRepository retryAttemptRepository;
    private final RecoveryExecutionService recoveryExecutionService;

    /**
     * Periodic background job to poll and trigger retries for eligible events.
     */
    @Scheduled(fixedDelay = 60000)
    public void scheduledRetryJob() {
        runScheduledRetries(false);
    }

    /**
     * Polls events with RETRY_SCHEDULED status and executes retries if cooldown has passed.
     * @param ignoreCooldown when true, bypasses the time check (useful for manual batch triggers or testing)
     * @return count of retries processed
     */
    public int runScheduledRetries(boolean ignoreCooldown) {
        log.info("[STAGE 4: SCHEDULER] Scanning for retry-eligible events (ignoreCooldown={})", ignoreCooldown);

        List<PaymentEvent> scheduledEvents = paymentEventRepository.findByStatus(PaymentStatus.RETRY_SCHEDULED.name());
        if (scheduledEvents.isEmpty()) {
            log.debug("[STAGE 4: SCHEDULER] No events currently scheduled for retry.");
            return 0;
        }

        int retriesExecuted = 0;
        OffsetDateTime now = OffsetDateTime.now();

        for (PaymentEvent event : scheduledEvents) {
            boolean eligible = ignoreCooldown;

            if (!eligible) {
                // Determine cooldown from active policy
                int cooldownSeconds = 86400; // default 24h
                Optional<RecoveryPolicy> policyOpt = policyRepository.findByReasonCodeAndActiveTrue(event.getRawFailureCode());
                if (policyOpt.isPresent() && policyOpt.get().getCooldownSeconds() != null) {
                    cooldownSeconds = policyOpt.get().getCooldownSeconds();
                }

                // Check time since last attempt or event creation
                List<RetryAttempt> pastAttempts = retryAttemptRepository.findByPaymentEventIdOrderByAttemptNumberAsc(event.getId());
                OffsetDateTime lastReferenceTime = pastAttempts.isEmpty()
                        ? event.getCreatedAt()
                        : pastAttempts.get(pastAttempts.size() - 1).getAttemptedAt();

                long elapsedSeconds = Duration.between(lastReferenceTime, now).getSeconds();
                if (elapsedSeconds >= cooldownSeconds) {
                    eligible = true;
                } else {
                    log.debug("[STAGE 4: SCHEDULER] Event {} still in cooldown (elapsed: {}s, required: {}s)",
                            event.getEventId(), elapsedSeconds, cooldownSeconds);
                }
            }

            if (eligible) {
                int nextAttempt = retryAttemptRepository.countByPaymentEventId(event.getId()) + 1;
                log.info("[STAGE 4: SCHEDULER] Triggering retry attempt {} for event {}", nextAttempt, event.getEventId());

                try {
                    ExecutionResult result = recoveryExecutionService.executeRetry(event, nextAttempt);
                    retriesExecuted++;
                    log.info("[STAGE 4: SCHEDULER] Event {} retry attempt {} completed with status {}",
                            event.getEventId(), nextAttempt, result.getStatus());
                } catch (Exception ex) {
                    log.error("[STAGE 4: SCHEDULER] Error executing retry attempt {} for event {}: {}",
                            nextAttempt, event.getEventId(), ex.getMessage(), ex);
                }
            }
        }

        log.info("[STAGE 4: SCHEDULER] Completed retry execution run: {} retries triggered", retriesExecuted);
        return retriesExecuted;
    }
}
