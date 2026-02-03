package com.swp391.bike_platform.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class VerifyUserRequest {
    @NotNull(message = "User ID is required")
    private Long userId;

    @NotBlank(message = "Action is required (APPROVE or REJECT)")
    private String action; // "APPROVE" or "REJECT"

    private String reason; // Required if action is "REJECT"
}
