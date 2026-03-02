package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByUser_UserIdOrderByCreatedAtDesc(Long userId);

    Optional<Transaction> findByVnpTxnRef(String vnpTxnRef);
}
