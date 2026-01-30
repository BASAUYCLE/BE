package com.swp391.bike_platform.service;

import com.swp391.bike_platform.request.UserLoginRequest;
import com.swp391.bike_platform.request.UserRegisterRequest;
import com.swp391.bike_platform.request.UserUpdateRequest;
import com.swp391.bike_platform.response.UserResponse;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.UserEnum;
import com.swp391.bike_platform.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final CloudinaryService cloudinaryService;

    public UserResponse createUser(UserRegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail()))
            throw new AppException(ErrorCode.USER_EXISTED);

        User user = new User();

        user.setEmail(request.getEmail().trim());
        user.setPassword(passwordEncoder.encode(request.getPassword())); // Encrypt password
        user.setFullName(request.getFullName().trim());
        user.setPhoneNumber(request.getPhoneNumber().trim());
        user.setRole(UserEnum.MEMBER); // Default role for registration

        // Upload CCCD images to Cloudinary
        try {
            if (request.getCccdFront() != null && !request.getCccdFront().isEmpty()) {
                user.setCccdFront(cloudinaryService.uploadImage(request.getCccdFront()));
            }
            if (request.getCccdBack() != null && !request.getCccdBack().isEmpty()) {
                user.setCccdBack(cloudinaryService.uploadImage(request.getCccdBack()));
            }
        } catch (java.io.IOException e) {
            throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
        }

        user.setIsVerified("PENDING");

        return toUserResponse(userRepository.save(user));
    }

    public User authenticate(UserLoginRequest request) {
        var user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        // Use BCrypt to verify password
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }

        return user;
    }

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::toUserResponse)
                .collect(Collectors.toList());
    }

    public UserResponse getUserById(Long id) {
        return toUserResponse(userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED)));
    }

    public UserResponse getUserByEmail(String email) {
        return toUserResponse(userRepository.findByEmail(email)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED)));
    }

    public UserResponse updateUser(Long id, UserUpdateRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        if (request.getFullName() != null)
            user.setFullName(request.getFullName());
        if (request.getPhoneNumber() != null)
            user.setPhoneNumber(request.getPhoneNumber());

        return toUserResponse(userRepository.save(user));
    }

    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new AppException(ErrorCode.USER_NOT_EXISTED);
        }
        userRepository.deleteById(id);
    }

    private UserResponse toUserResponse(User user) {
        return UserResponse.builder()
                .userId(user.getUserId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole())
                .cccdFront(user.getCccdFront())
                .cccdBack(user.getCccdBack())
                .isVerified(user.getIsVerified())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
