package com.swp391.bike_platform.controller.user;

import com.swp391.bike_platform.request.UserUpdateRequest;
import com.swp391.bike_platform.response.UserResponse;
import com.swp391.bike_platform.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    // ============ ENDPOINTS FOR CURRENT USER (ALL ROLES) ============

    @GetMapping("/myinfo")
    UserResponse getMyInfo(@AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        return userService.getUserById(userId);
    }

    @PutMapping("/myinfo")
    UserResponse updateMyInfo(@AuthenticationPrincipal Jwt jwt,
            @RequestBody UserUpdateRequest request) {
        Long userId = jwt.getClaim("userId");
        return userService.updateUser(userId, request);
    }

    // ============ ADMIN ONLY ENDPOINTS ============

    @GetMapping
    List<UserResponse> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/{userId}")
    UserResponse getUser(@PathVariable Long userId) {
        return userService.getUserById(userId);
    }

    @GetMapping("/email/{email}")
    UserResponse getUserByEmail(@PathVariable String email) {
        return userService.getUserByEmail(email);
    }

    @PutMapping("/{userId}")
    UserResponse updateUser(@PathVariable Long userId,
            @RequestBody UserUpdateRequest request) {
        return userService.updateUser(userId, request);
    }

    @DeleteMapping("/{userId}")
    String deleteUser(@PathVariable Long userId) {
        userService.deleteUser(userId);
        return "User has been deleted";
    }
}
