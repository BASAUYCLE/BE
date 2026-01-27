package com.swp391.bike_platform.entity;

import com.swp391.bike_platform.enums.UserEnum;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "Users") // Tên bảng trong SQL Server
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "user_email", nullable = false, unique = true)
    private String email;

    @Column(name = "user_password_hash", nullable = false)
    private String password;

    @Column(name = "user_full_name", nullable = false, columnDefinition = "NVARCHAR(100)")
    private String fullName;

    @Column(name = "user_phone_number", length = 15)
    private String phoneNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "user_role", nullable = false)
    private UserEnum role;

    // Lưu ảnh Base64 cực dài nên phải dùng NVARCHAR(MAX)
    @Column(name = "cccd_front", columnDefinition = "NVARCHAR(MAX)")
    private String cccdFront;

    @Column(name = "cccd_back", columnDefinition = "NVARCHAR(MAX)")
    private String cccdBack;

    // Trạng thái xác minh: PENDING, VERIFIED, REJECTED
    @Column(name = "is_verified", length = 20)
    private String isVerified;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}