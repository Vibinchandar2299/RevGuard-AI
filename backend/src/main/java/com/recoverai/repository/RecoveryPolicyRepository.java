package com.recoverai.repository;

import com.recoverai.entity.RecoveryPolicy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RecoveryPolicyRepository extends JpaRepository<RecoveryPolicy, UUID> {
    List<RecoveryPolicy> findByActiveTrue();
    long countByActiveTrue();
    Optional<RecoveryPolicy> findByReasonCodeAndActiveTrue(String reasonCode);
    Optional<RecoveryPolicy> findByReasonCodeAndVersion(String reasonCode, Integer version);
}
