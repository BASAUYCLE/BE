package com.swp391.bike_platform.controller.auth;

import com.swp391.bike_platform.request.UserLoginRequest;
import com.swp391.bike_platform.request.UserRegisterRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.swp391.bike_platform.response.UserResponse;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UserService userService;

    @PostMapping("/register")
    ApiResponse<UserResponse> register(
            @org.springframework.web.bind.annotation.ModelAttribute UserRegisterRequest request) {
        return ApiResponse.<UserResponse>builder()
                .result(userService.createUser(request))
                .build();
    }

    @PostMapping("/login")
    ApiResponse<String> login(@RequestBody UserLoginRequest request) {
        boolean isAuthenticated = userService.authenticate(request);
        if (isAuthenticated) {
            return ApiResponse.<String>builder()
                    .result("Login Successful!")
                    .build();
        } else {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }
    }
}
