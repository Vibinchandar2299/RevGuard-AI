package com.recoverai.repository;

import com.recoverai.entity.RecoveryAction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RecoveryActionRepository extends JpaRepository<RecoveryAction, UUID> {
    List<RecoveryAction> findByPaymentEventId(UUID paymentEventId);
    List<RecoveryAction> findByPaymentEventIdOrderByCreatedAtDesc(UUID paymentEventId);
}
