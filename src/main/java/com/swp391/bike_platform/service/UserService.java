package com.swp391.bike_platform.service;

import com.swp391.bike_platform.dto.request.UserLoginRequest;
import com.swp391.bike_platform.dto.request.UserRegisterRequest;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.UserEnum;
import com.swp391.bike_platform.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final ImgBBService imgBBService;

    public User createUser(UserRegisterRequest request) {
        User user = new User();

        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword())); // Encrypt password
        user.setFullName(request.getFullName());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setRole(UserEnum.MEMBER); // Default role for registration

        // Upload CCCD images to ImgBB
        try {
            if (request.getCccdFront() != null && !request.getCccdFront().isEmpty()) {
                user.setCccdFront(imgBBService.uploadImage(request.getCccdFront()));
            }
            if (request.getCccdBack() != null && !request.getCccdBack().isEmpty()) {
                user.setCccdBack(imgBBService.uploadImage(request.getCccdBack()));
            }
        } catch (java.io.IOException e) {
            throw new RuntimeException("Failed to upload CCCD images: " + e.getMessage());
        }

        user.setIsVerified("PENDING");

        return userRepository.save(user);
    }

    public boolean authenticate(UserLoginRequest request) {
        var user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Use BCrypt to verify password
        return passwordEncoder.matches(request.getPassword(), user.getPassword());
    }

    public java.util.List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    public User updateUser(Long id, com.swp391.bike_platform.dto.request.UserUpdateRequest request) {
        User user = getUserById(id);

        if (request.getFullName() != null)
            user.setFullName(request.getFullName());
        if (request.getPhoneNumber() != null)
            user.setPhoneNumber(request.getPhoneNumber());

        return userRepository.save(user);
    }

    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new RuntimeException("User not found");
        }
        userRepository.deleteById(id);
    }
}
