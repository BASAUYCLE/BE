package com.swp391.bike_platform.request;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class TopUpRequest {
    private BigDecimal amount;
}
