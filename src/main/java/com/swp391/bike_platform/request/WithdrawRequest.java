package com.swp391.bike_platform.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WithdrawRequest {
    @NotNull(message = "MISSING_REQUIRED_FIELD")
    @Min(value = 50000, message = "WITHDRAW_MIN_AMOUNT")
    private BigDecimal amount;

    @NotBlank(message = "MISSING_REQUIRED_FIELD")
    private String bankName;

    @NotBlank(message = "MISSING_REQUIRED_FIELD")
    private String bankAccountNumber;

    @NotBlank(message = "MISSING_REQUIRED_FIELD")
    private String bankAccountHolder;
}
