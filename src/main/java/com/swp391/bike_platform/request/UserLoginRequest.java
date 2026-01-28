package com.swp391.bike_platform.request;

import lombok.Data;

@Data
public class UserLoginRequest {
    private String email;
    private String password;
}
