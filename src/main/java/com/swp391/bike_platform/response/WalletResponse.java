package com.swp391.bike_platform.response;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WalletResponse {
    private Long walletId;
    private Long userId;
    private BigDecimal balance;
    private LocalDateTime createdAt;
}
