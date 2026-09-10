package com.recoverai.service;

import com.recoverai.dto.MessageDraftResponse;
import com.recoverai.entity.AuditLog;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.entity.RecoveryMessage;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.repository.AuditLogRepository;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.repository.RecoveryMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DraftService {

    private final RecoveryMessageRepository messageRepository;
    private final PaymentEventRepository paymentEventRepository;
    private final AuditLogRepository auditLogRepository;

    /**
     * Creates a customer recovery communication draft with status DRAFTED.
     */
    @Transactional
    public RecoveryMessage createDraftForEvent(PaymentEvent event) {
        log.info("[STAGE 2/3: MESSAGING DRAFT] Generating recovery message draft for event {}", event.getEventId());

        String customerName = event.getCustomer() != null ? event.getCustomer().getName() : "Valued Customer";
        String recipient = event.getCustomer() != null && event.getCustomer().getEmail() != null
                ? event.getCustomer().getEmail()
                : "customer@example.com";

        String reason = event.getRawFailureCode() != null ? event.getRawFailureCode().toLowerCase() : "unknown";
        String subject;
        String body;

        if (reason.contains("insufficient") || reason.contains("fund")) {
            subject = "Action Required: Update payment method for your subscription";
            body = String.format("Hi %s,\n\nWe were unable to process your payment of Rs %.2f due to insufficient funds. Please ensure sufficient balance or update your payment details to prevent service interruption.\n\nThank you,\nRevGuard Team",
                    customerName, event.getAmount());
        } else if (reason.contains("expired")) {
            subject = "Urgent: Your payment card has expired";
            body = String.format("Hi %s,\n\nYour card on file for payment of Rs %.2f has expired. Please update your card information to keep your account active.\n\nThank you,\nRevGuard Team",
                    customerName, event.getAmount());
        } else if (reason.contains("bank") || reason.contains("decline")) {
            subject = "Payment Notice: Bank authorization declined";
            body = String.format("Hi %s,\n\nYour bank declined a charge of Rs %.2f. Please contact your card issuer to authorize future recurring charges, or retry with another payment method.\n\nThank you,\nRevGuard Team",
                    customerName, event.getAmount());
        } else if (reason.contains("fraud")) {
            subject = "Security Notice: Payment authorization required";
            body = String.format("Hi %s,\n\nA transaction of Rs %.2f was flagged for additional verification. Please contact our risk security team.\n\nThank you,\nRevGuard Team",
                    customerName, event.getAmount());
        } else {
            subject = "Payment Notice: Failed charge on your account";
            body = String.format("Hi %s,\n\nWe encountered an issue processing your payment of Rs %.2f (%s). Please review your payment settings.\n\nThank you,\nRevGuard Team",
                    customerName, event.getAmount(), reason);
        }

        RecoveryMessage message = RecoveryMessage.builder()
                .paymentEvent(event)
                .channel("EMAIL")
                .recipient(recipient)
                .subject(subject)
                .body(body)
                .status("DRAFTED")
                .build();

        RecoveryMessage saved = messageRepository.save(message);

        auditLogRepository.save(AuditLog.builder()
                .paymentEvent(event)
                .actor(AuditActor.SYSTEM.name())
                .action("DRAFT_CREATED")
                .reason(String.format("Generated %s draft for customer %s (%s)", saved.getChannel(), customerName, recipient))
                .build());

        log.info("[STAGE 2/3: MESSAGING DRAFT] Draft message created with id {} for event {}", saved.getId(), event.getEventId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<MessageDraftResponse> getPendingDrafts() {
        return messageRepository.findByStatus("DRAFTED").stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MessageDraftResponse> getAllMessages() {
        return messageRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public MessageDraftResponse approveMessage(UUID messageId, String reviewer, String comments) {
        RecoveryMessage message = messageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("Recovery message not found: " + messageId));

        message.setStatus("SENT");
        message.setSentAt(OffsetDateTime.now());
        RecoveryMessage saved = messageRepository.save(message);

        String actorName = reviewer != null && !reviewer.isBlank() ? reviewer : "HUMAN";
        String auditReason = String.format("Message approved and dispatched by %s%s",
                actorName, comments != null && !comments.isBlank() ? " (" + comments + ")" : "");

        auditLogRepository.save(AuditLog.builder()
                .paymentEvent(message.getPaymentEvent())
                .actor(AuditActor.HUMAN.name())
                .action("MESSAGE_APPROVED")
                .reason(auditReason)
                .build());

        log.info("[MESSAGING REVIEW] Message {} approved by {}", messageId, actorName);
        return mapToResponse(saved);
    }

    @Transactional
    public MessageDraftResponse rejectMessage(UUID messageId, String reviewer, String comments) {
        RecoveryMessage message = messageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("Recovery message not found: " + messageId));

        message.setStatus("REJECTED");
        RecoveryMessage saved = messageRepository.save(message);

        String actorName = reviewer != null && !reviewer.isBlank() ? reviewer : "HUMAN";
        String auditReason = String.format("Message draft rejected by %s%s",
                actorName, comments != null && !comments.isBlank() ? " (" + comments + ")" : "");

        auditLogRepository.save(AuditLog.builder()
                .paymentEvent(message.getPaymentEvent())
                .actor(AuditActor.HUMAN.name())
                .action("MESSAGE_REJECTED")
                .reason(auditReason)
                .build());

        log.info("[MESSAGING REVIEW] Message {} rejected by {}", messageId, actorName);
        return mapToResponse(saved);
    }

    private MessageDraftResponse mapToResponse(RecoveryMessage m) {
        PaymentEvent event = m.getPaymentEvent();
        String custName = event != null && event.getCustomer() != null ? event.getCustomer().getName() : null;
        String custEmail = event != null && event.getCustomer() != null ? event.getCustomer().getEmail() : null;

        return MessageDraftResponse.builder()
                .id(m.getId())
                .paymentEventId(event != null ? event.getId() : null)
                .eventId(event != null ? event.getEventId() : null)
                .customerName(custName)
                .customerEmail(custEmail)
                .channel(m.getChannel())
                .subject(m.getSubject())
                .body(m.getBody())
                .status(m.getStatus())
                .createdAt(m.getCreatedAt())
                .sentAt(m.getSentAt())
                .build();
    }
}
