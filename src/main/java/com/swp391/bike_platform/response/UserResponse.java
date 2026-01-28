package com.swp391.bike_platform.response;

import com.swp391.bike_platform.enums.UserEnum;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private Long userId;
    private String email;
    private String fullName;
    private String phoneNumber;
    private UserEnum role;
    private String cccdFront;
    private String cccdBack;
    private String isVerified;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

/// tranh lo mat khau da ma hoa len response
