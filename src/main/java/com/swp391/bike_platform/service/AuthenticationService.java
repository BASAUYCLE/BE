package com.swp391.bike_platform.service;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.request.IntrospectRequest;
import com.swp391.bike_platform.response.IntrospectResponse;
import lombok.RequiredArgsConstructor;
import lombok.experimental.NonFinal;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.text.ParseException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    @NonFinal
    @Value("${jwt.signer-key}")
    protected String SIGNER_KEY;

    @NonFinal
    @Value("${jwt.expiration}")
    protected long EXPIRATION_TIME;

    /**
     * Generate JWT token for authenticated user
     */
    public String generateToken(User user) {
        // Create JWT header with HS512 algorithm
        JWSHeader header = new JWSHeader(JWSAlgorithm.HS512);

        // Build claims
        JWTClaimsSet jwtClaimsSet = new JWTClaimsSet.Builder()
                .subject(user.getEmail())
                .issuer("bike-platform")
                .issueTime(new Date())
                .expirationTime(new Date(
                        Instant.now().plus(EXPIRATION_TIME, ChronoUnit.SECONDS).toEpochMilli()))
                .claim("userId", user.getUserId())
                .claim("role", user.getRole().name())
                .build();

        // Create payload
        Payload payload = new Payload(jwtClaimsSet.toJSONObject());

        // Create signed JWT
        JWSObject jwsObject = new JWSObject(header, payload);

        try {
            jwsObject.sign(new MACSigner(SIGNER_KEY.getBytes()));
            return jwsObject.serialize();
        } catch (JOSEException e) {
            throw new RuntimeException("Cannot create token", e);
        }
    }

    /**
     * Introspect token to check if it's valid
     */
    public IntrospectResponse introspect(IntrospectRequest request) {
        String token = request.getToken();
        boolean isValid = true;

        try {
            verifyToken(token);
        } catch (AppException | ParseException | JOSEException e) {
            isValid = false;
        }

        return IntrospectResponse.builder()
                .valid(isValid)
                .build();
    }

    /**
     * Verify token signature and expiration
     */
    private void verifyToken(String token) throws ParseException, JOSEException {
        // Parse the token
        SignedJWT signedJWT = SignedJWT.parse(token);

        // Verify signature
        JWSVerifier verifier = new MACVerifier(SIGNER_KEY.getBytes());
        boolean verified = signedJWT.verify(verifier);

        if (!verified) {
            throw new AppException(ErrorCode.INVALID_TOKEN);
        }

        // Check expiration
        Date expirationTime = signedJWT.getJWTClaimsSet().getExpirationTime();
        if (expirationTime.before(new Date())) {
            throw new AppException(ErrorCode.TOKEN_EXPIRED);
        }
    }
}
