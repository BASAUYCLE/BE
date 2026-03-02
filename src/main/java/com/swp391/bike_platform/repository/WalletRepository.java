package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface WalletRepository extends JpaRepository<Wallet, Long> {
    Optional<Wallet> findByUser_UserId(Long userId);

    boolean existsByUser_UserId(Long userId);
}
