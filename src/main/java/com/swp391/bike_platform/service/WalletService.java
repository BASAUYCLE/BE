package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.entity.Wallet;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.WalletRepository;
import com.swp391.bike_platform.response.WalletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;
    private final UserService userService;

    /**
     * Get or create wallet for a user
     */
    @Transactional
    public Wallet getOrCreateWallet(Long userId) {
        return walletRepository.findByUser_UserId(userId)
                .orElseGet(() -> {
                    User user = userService.getUserEntityById(userId);
                    Wallet wallet = Wallet.builder()
                            .user(user)
                            .balance(BigDecimal.ZERO)
                            .build();
                    return walletRepository.save(wallet);
                });
    }

    /**
     * Get wallet response (auto-create if not exists)
     */
    public WalletResponse getWalletResponse(Long userId) {
        Wallet wallet = getOrCreateWallet(userId);
        return toResponse(wallet);
    }

    /**
     * Add balance (when top-up succeeds)
     */
    @Transactional
    public void addBalance(Long walletId, BigDecimal amount) {
        Wallet wallet = walletRepository.findById(walletId)
                .orElseThrow(() -> new AppException(ErrorCode.WALLET_NOT_FOUND));
        wallet.setBalance(wallet.getBalance().add(amount));
        walletRepository.save(wallet);
    }

    /**
     * Deduct balance (for deposit/purchase - phase sau)
     */
    @Transactional
    public void deductBalance(Long walletId, BigDecimal amount) {
        Wallet wallet = walletRepository.findById(walletId)
                .orElseThrow(() -> new AppException(ErrorCode.WALLET_NOT_FOUND));
        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new AppException(ErrorCode.INSUFFICIENT_BALANCE);
        }
        wallet.setBalance(wallet.getBalance().subtract(amount));
        walletRepository.save(wallet);
    }

    private WalletResponse toResponse(Wallet w) {
        return WalletResponse.builder()
                .walletId(w.getWalletId())
                .userId(w.getUser().getUserId())
                .balance(w.getBalance())
                .createdAt(w.getCreatedAt())
                .build();
    }
}
