package com.swp391.bike_platform.request;

import lombok.Data;

@Data
public class UserUpdateRequest {
    private String fullName;
    private String phoneNumber;
    private String email;
    private String address;
}
