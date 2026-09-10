package com.recoverai.repository;

import com.recoverai.entity.RecoveryBatch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface RecoveryBatchRepository extends JpaRepository<RecoveryBatch, UUID> {
    Optional<RecoveryBatch> findByBatchName(String batchName);
    Optional<RecoveryBatch> findTopByOrderByCreatedAtDesc();
}
