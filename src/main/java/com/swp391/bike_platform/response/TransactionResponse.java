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
    private String vnpTxnRef;
    private String vnpTransactionNo;
    private Long postId;
    private Long userId;
    private String userEmail;
    private String userFullName;
    private String bankName;
    private String bankAccountNumber;
    private String bankAccountHolder;
    private LocalDateTime createdAt;
}
