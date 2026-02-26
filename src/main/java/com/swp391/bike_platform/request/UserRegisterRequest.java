package com.swp391.bike_platform.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class UserRegisterRequest {
    @Email(message = "INVALID_EMAIL")
    private String email;

    @Size(min = 8, message = "INVALID_PASSWORD")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$", message = "WEAK_PASSWORD")
    private String password;
    private String fullName;
    private String phoneNumber;
    private MultipartFile cccdFront;
    private MultipartFile cccdBack;
}
