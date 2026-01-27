package com.swp391.bike_platform.dto.request;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class UserRegisterRequest {
    private String email;
    private String password;
    private String fullName;
    private String phoneNumber;
    private MultipartFile cccdFront;
    private MultipartFile cccdBack;
}
