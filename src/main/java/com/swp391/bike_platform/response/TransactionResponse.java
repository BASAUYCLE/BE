package com.swp391.bike_platform.response;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionResponse {
    private Long transactionId;
    private String transactionType;
    private BigDecimal amount;
    private String status;
    private String description;
    private String vnpBankCode;
    private Long postId;
    private LocalDateTime createdAt;
}
