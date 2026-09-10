package com.recoverai.repository;

import com.recoverai.entity.Classification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassificationRepository extends JpaRepository<Classification, UUID> {
    Optional<Classification> findByPaymentEventId(UUID paymentEventId);
    boolean existsByPaymentEventId(UUID paymentEventId);
}
