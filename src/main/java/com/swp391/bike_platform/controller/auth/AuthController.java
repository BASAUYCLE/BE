package com.swp391.bike_platform.controller.auth;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.IntrospectRequest;
import com.swp391.bike_platform.request.UserLoginRequest;
import com.swp391.bike_platform.request.UserRegisterRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.AuthenticationResponse;
import com.swp391.bike_platform.response.IntrospectResponse;
import com.swp391.bike_platform.response.UserResponse;
import com.swp391.bike_platform.service.AuthenticationService;
import com.swp391.bike_platform.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
        private final UserService userService;
        private final AuthenticationService authenticationService;

        @PostMapping("/register")
        ApiResponse<UserResponse> register(
                        @ModelAttribute @Valid UserRegisterRequest request) {
                return ApiResponse.<UserResponse>builder()
                                .result(userService.createUser(request))
                                .build();
        }

        @PostMapping("/login")
        ApiResponse<AuthenticationResponse> login(@RequestBody UserLoginRequest request) {
                // Authenticate user
                User user = userService.authenticate(request);

                // Generate JWT token
                String token = authenticationService.generateToken(user);

                // Return token response
                return ApiResponse.<AuthenticationResponse>builder()
                                .result(AuthenticationResponse.builder()
                                                .token(token)
                                                .authenticated(true)
                                                .build())
                                .build();
        }

        @PostMapping("/introspect")
        ApiResponse<IntrospectResponse> introspect(@RequestBody IntrospectRequest request) {
                IntrospectResponse result = authenticationService.introspect(request);
                return ApiResponse.<IntrospectResponse>builder()
                                .result(result)
                                .build();
        }
}
