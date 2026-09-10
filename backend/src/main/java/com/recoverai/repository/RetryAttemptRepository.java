package com.recoverai.repository;

import com.recoverai.entity.RetryAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RetryAttemptRepository extends JpaRepository<RetryAttempt, UUID> {
    List<RetryAttempt> findByPaymentEventIdOrderByAttemptNumberAsc(UUID paymentEventId);
    Optional<RetryAttempt> findByPaymentEventIdAndAttemptNumber(UUID paymentEventId, Integer attemptNumber);
    int countByPaymentEventId(UUID paymentEventId);
}
