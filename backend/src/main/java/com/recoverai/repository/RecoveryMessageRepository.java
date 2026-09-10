package com.recoverai.repository;

import com.recoverai.entity.RecoveryMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RecoveryMessageRepository extends JpaRepository<RecoveryMessage, UUID> {
    List<RecoveryMessage> findByPaymentEventId(UUID paymentEventId);
    List<RecoveryMessage> findByStatus(String status);
}
