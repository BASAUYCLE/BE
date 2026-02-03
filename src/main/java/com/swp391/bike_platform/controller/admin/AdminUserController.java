package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.VerifyUserRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.member.UserResponse;
import com.swp391.bike_platform.service.EmailService;
import com.swp391.bike_platform.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
@Slf4j
public class AdminUserController {

    private final UserService userService;
    private final EmailService emailService;

    /**
     * Get all users
     */
    @GetMapping
    public ApiResponse<List<UserResponse>> getAllUsers() {
        return ApiResponse.<List<UserResponse>>builder()
                .result(userService.getAllUsers())
                .build();
    }

    /**
     * Get all pending verification users
     */
    @GetMapping("/pending")
    public ApiResponse<List<UserResponse>> getPendingUsers() {
        return ApiResponse.<List<UserResponse>>builder()
                .result(userService.getPendingUsers())
                .build();
    }

    /**
     * Verify user (APPROVE or REJECT)
     * Sends email notification to user
     */
    @PostMapping("/verify")
    public ApiResponse<UserResponse> verifyUser(@Valid @RequestBody VerifyUserRequest request) {
        log.info("Admin verifying user {} with action: {}", request.getUserId(), request.getAction());

        // Get user entity before update (for email)
        User user = userService.getUserEntityById(request.getUserId());

        // Update verification status
        UserResponse response = userService.verifyUser(
                request.getUserId(),
                request.getAction(),
                request.getReason());

        // Send email notification
        if (request.getAction().equalsIgnoreCase("APPROVE")) {
            emailService.sendVerificationApprovedEmail(user);
            log.info("Verification approved email sent to: {}", user.getEmail());
        } else {
            emailService.sendVerificationRejectedEmail(user, request.getReason());
            log.info("Verification rejected email sent to: {}", user.getEmail());
        }

        return ApiResponse.<UserResponse>builder()
                .result(response)
                .message(request.getAction().equalsIgnoreCase("APPROVE")
                        ? "User verified successfully"
                        : "User rejected successfully")
                .build();
    }

    /**
     * Get user by ID
     */
    @GetMapping("/{userId}")
    public ApiResponse<UserResponse> getUserById(@PathVariable Long userId) {
        return ApiResponse.<UserResponse>builder()
                .result(userService.getUserById(userId))
                .build();
    }
}
