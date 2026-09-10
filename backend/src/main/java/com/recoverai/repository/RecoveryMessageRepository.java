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

    @org.springframework.data.jpa.repository.Query("SELECT m FROM RecoveryMessage m LEFT JOIN FETCH m.paymentEvent p LEFT JOIN FETCH p.customer WHERE m.status = :status")
    List<RecoveryMessage> findByStatusWithDetails(@org.springframework.data.repository.query.Param("status") String status);

    @org.springframework.data.jpa.repository.Query("SELECT m FROM RecoveryMessage m LEFT JOIN FETCH m.paymentEvent p LEFT JOIN FETCH p.customer")
    List<RecoveryMessage> findAllWithDetails();

    @org.springframework.data.jpa.repository.Query("SELECT m FROM RecoveryMessage m LEFT JOIN FETCH m.paymentEvent p LEFT JOIN FETCH p.customer WHERE m.id = :id")
    java.util.Optional<RecoveryMessage> findByIdWithDetails(@org.springframework.data.repository.query.Param("id") UUID id);
}
