package com.recoverai.repository;

import com.recoverai.entity.PaymentEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PaymentEventRepository extends JpaRepository<PaymentEvent, UUID> {
    Optional<PaymentEvent> findByEventId(String eventId);
    boolean existsByEventId(String eventId);
    List<PaymentEvent> findByBatchId(UUID batchId);
    List<PaymentEvent> findByStatus(String status);
    List<PaymentEvent> findTop50ByOrderByCreatedAtDesc();
}
