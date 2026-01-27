package com.swp391.bike_platform.controller.auth;

import com.swp391.bike_platform.dto.request.UserLoginRequest;
import com.swp391.bike_platform.dto.request.UserRegisterRequest;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UserService userService;

    @PostMapping("/register")
    User register(@org.springframework.web.bind.annotation.ModelAttribute UserRegisterRequest request) {
        return userService.createUser(request);
    }

    @PostMapping("/login")
    String login(@RequestBody UserLoginRequest request) {
        boolean isAuthenticated = userService.authenticate(request);
        if (isAuthenticated) {
            return "Login Successful!";
        } else {
            throw new RuntimeException("Invalid Credentials"); // Should handle with proper exception
        }
    }
}
