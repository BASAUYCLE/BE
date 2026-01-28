package com.swp391.bike_platform.controller.user;

import com.swp391.bike_platform.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import com.swp391.bike_platform.response.UserResponse;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    @GetMapping
    java.util.List<UserResponse> getAllUsers() {
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
            @RequestBody com.swp391.bike_platform.request.UserUpdateRequest request) {
        return userService.updateUser(userId, request);
    }

    @DeleteMapping("/{userId}")
    String deleteUser(@PathVariable Long userId) {
        userService.deleteUser(userId);
        return "User has been deleted";
    }

    // Endpoint moved to AuthController
    // Keep UserController for future profile management APIs
}
