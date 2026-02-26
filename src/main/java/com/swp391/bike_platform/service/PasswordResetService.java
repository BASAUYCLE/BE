package com.swp391.bike_platform.service;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.experimental.NonFinal;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.text.ParseException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
@RequiredArgsConstructor
@Slf4j
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    @NonFinal
    @Value("${jwt.signer-key}")
    protected String SIGNER_KEY;

    @NonFinal
    @Value("${app.frontend-url}")
    protected String frontendUrl;

    private static final String RESET_PURPOSE = "RESET_PASSWORD";
    private static final long RESET_TOKEN_EXPIRY_MINUTES = 15;

    /**
     * Step 1: User requests password reset → generate JWT token → send email
     */
    public void requestPasswordReset(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        // Generate reset token (JWT with purpose claim)
        String resetToken = generateResetToken(user);

        // Build reset link
        String resetLink = frontendUrl + "/reset-password?token=" + resetToken;

        // Send email
        emailService.sendPasswordResetEmail(user, resetLink);

        log.info("Password reset email sent to: {}", email);
    }

    /**
     * Step 2: User submits new password with token → verify token → update password
     */
    public void resetPassword(String token, String newPassword) {
        try {
            // Parse and verify the JWT token
            SignedJWT signedJWT = SignedJWT.parse(token);
            JWSVerifier verifier = new MACVerifier(SIGNER_KEY.getBytes());

            if (!signedJWT.verify(verifier)) {
                throw new AppException(ErrorCode.INVALID_RESET_TOKEN);
            }

            JWTClaimsSet claims = signedJWT.getJWTClaimsSet();

            // Check purpose claim
            String purpose = claims.getStringClaim("purpose");
            if (!RESET_PURPOSE.equals(purpose)) {
                throw new AppException(ErrorCode.INVALID_RESET_TOKEN);
            }

            // Check expiration
            Date expirationTime = claims.getExpirationTime();
            if (expirationTime == null || expirationTime.before(new Date())) {
                throw new AppException(ErrorCode.RESET_TOKEN_EXPIRED);
            }

            // Get userId from claims
            Long userId = claims.getLongClaim("userId");
            if (userId == null) {
                throw new AppException(ErrorCode.INVALID_RESET_TOKEN);
            }

            // Find user and update password
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

            user.setPassword(passwordEncoder.encode(newPassword));
            userRepository.save(user);

            log.info("Password reset successfully for user: {}", user.getEmail());

        } catch (ParseException | JOSEException e) {
            log.error("Failed to verify reset token: {}", e.getMessage());
            throw new AppException(ErrorCode.INVALID_RESET_TOKEN);
        }
    }

    /**
     * Generate a short-lived JWT token specifically for password reset
     */
    private String generateResetToken(User user) {
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);

        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(user.getEmail())
                .issuer("bike-platform")
                .issueTime(new Date())
                .expirationTime(new Date(
                        Instant.now().plus(RESET_TOKEN_EXPIRY_MINUTES, ChronoUnit.MINUTES).toEpochMilli()))
                .claim("userId", user.getUserId())
                .claim("purpose", RESET_PURPOSE)
                .build();

        Payload payload = new Payload(claimsSet.toJSONObject());
        JWSObject jwsObject = new JWSObject(header, payload);

        try {
            jwsObject.sign(new MACSigner(SIGNER_KEY.getBytes()));
            return jwsObject.serialize();
        } catch (JOSEException e) {
            log.error("Failed to generate reset token: {}", e.getMessage());
            throw new AppException(ErrorCode.TOKEN_CREATION_FAILED);
        }
    }
}
