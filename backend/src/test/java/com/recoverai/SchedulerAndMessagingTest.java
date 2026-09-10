package com.recoverai;

import com.recoverai.dto.MessageDraftResponse;
import com.recoverai.entity.AuditLog;
import com.recoverai.entity.Customer;
import com.recoverai.entity.PaymentEvent;
import com.recoverai.entity.RecoveryMessage;
import com.recoverai.model.enums.AuditActor;
import com.recoverai.model.enums.PaymentStatus;
import com.recoverai.repository.AuditLogRepository;
import com.recoverai.repository.CustomerRepository;
import com.recoverai.repository.PaymentEventRepository;
import com.recoverai.repository.RecoveryMessageRepository;
import com.recoverai.service.DraftService;
import com.recoverai.service.SchedulerService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class SchedulerAndMessagingTest {

    @Autowired
    private DraftService draftService;

    @Autowired
    private SchedulerService schedulerService;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private PaymentEventRepository paymentEventRepository;

    @Autowired
    private RecoveryMessageRepository messageRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Customer testCustomer;

    @BeforeEach
    void setUp() {
        testCustomer = customerRepository.save(Customer.builder()
                .name("Messaging Test Customer")
                .email("msg_test_" + UUID.randomUUID() + "@example.com")
                .build());
    }

    @AfterEach
    void tearDown() {
        jdbcTemplate.update("DELETE FROM recovery_messages WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_sched_%')");
        jdbcTemplate.update("DELETE FROM retry_attempts WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_sched_%')");
        jdbcTemplate.update("DELETE FROM audit_log WHERE payment_event_id IN (SELECT id FROM payment_events WHERE event_id LIKE 'evt_sched_%')");
        jdbcTemplate.update("DELETE FROM payment_events WHERE event_id LIKE 'evt_sched_%'");
        jdbcTemplate.update("DELETE FROM customers WHERE email LIKE 'msg_test_%'");
    }

    private PaymentEvent createEvent(String reasonCode, BigDecimal amount, PaymentStatus status) {
        return paymentEventRepository.save(PaymentEvent.builder()
                .eventId("evt_sched_" + UUID.randomUUID())
                .customer(testCustomer)
                .amount(amount)
                .currency("INR")
                .paymentMethod("CARD")
                .rawFailureCode(reasonCode)
                .rawFailureMessage("Failure: " + reasonCode)
                .status(status.name())
                .build());
    }

    @Test
    @DisplayName("DraftService: Generates contextual recovery message draft with status DRAFTED")
    void testCreateDraftForEvent() {
        PaymentEvent event = createEvent("card_expired", new BigDecimal("4999.00"), PaymentStatus.ESCALATED);

        RecoveryMessage draft = draftService.createDraftForEvent(event);

        assertThat(draft).isNotNull();
        assertThat(draft.getStatus()).isEqualTo("DRAFTED");
        assertThat(draft.getRecipient()).isEqualTo(testCustomer.getEmail());
        assertThat(draft.getSubject()).contains("expired");
        assertThat(draft.getBody()).contains("4999.00");

        // Verify audit log
        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "DRAFT_CREATED".equals(l.getAction()) && "SYSTEM".equals(l.getActor()));
    }

    @Test
    @DisplayName("DraftService: Human approves draft message -> marks SENT and logs HUMAN actor")
    void testApproveDraftMessage() {
        PaymentEvent event = createEvent("insufficient_funds", new BigDecimal("2500.00"), PaymentStatus.ESCALATED);
        RecoveryMessage draft = draftService.createDraftForEvent(event);

        MessageDraftResponse approved = draftService.approveMessage(draft.getId(), "OpsLead_Vibin", "Customer confirmed balance topped up");

        assertThat(approved.getStatus()).isEqualTo("SENT");
        assertThat(approved.getSentAt()).isNotNull();

        // Verify audit log with HUMAN actor
        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "MESSAGE_APPROVED".equals(l.getAction())
                && AuditActor.HUMAN.name().equals(l.getActor())
                && l.getReason().contains("OpsLead_Vibin"));
    }

    @Test
    @DisplayName("DraftService: Human rejects draft message -> marks REJECTED and logs HUMAN actor")
    void testRejectDraftMessage() {
        PaymentEvent event = createEvent("fraud_suspected", new BigDecimal("18000.00"), PaymentStatus.ESCALATED);
        RecoveryMessage draft = draftService.createDraftForEvent(event);

        MessageDraftResponse rejected = draftService.rejectMessage(draft.getId(), "SecurityLead_Alex", "High fraud score, do not email");

        assertThat(rejected.getStatus()).isEqualTo("REJECTED");

        // Verify audit log with HUMAN actor
        List<AuditLog> logs = auditLogRepository.findByPaymentEventIdOrderByCreatedAtDesc(event.getId());
        assertThat(logs).anyMatch(l -> "MESSAGE_REJECTED".equals(l.getAction())
                && AuditActor.HUMAN.name().equals(l.getActor())
                && l.getReason().contains("SecurityLead_Alex"));
    }

    @Test
    @DisplayName("SchedulerService: Scans and processes RETRY_SCHEDULED events")
    void testScheduler_ProcessesScheduledRetries() {
        PaymentEvent event = createEvent("network_timeout", new BigDecimal("3500.00"), PaymentStatus.RETRY_SCHEDULED);

        int processed = schedulerService.runScheduledRetries(true);

        assertThat(processed).isGreaterThanOrEqualTo(1);

        PaymentEvent updated = paymentEventRepository.findById(event.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(PaymentStatus.RECOVERED.name());
    }
}
