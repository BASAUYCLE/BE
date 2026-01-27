package com.swp391.bike_platform.dto.request;

import lombok.Data;

@Data
public class UserRegisterRequest {
    private String email;
    private String password;
    private String fullName;
    private String phoneNumber;
    private String cccdFront; // Base64 string
    private String cccdBack; // Base64 string
}
