package com.swp391.bike_platform.configuration;

import com.swp391.bike_platform.enums.UserEnum;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

import javax.crypto.spec.SecretKeySpec;
import java.util.Collections;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

        @Value("${jwt.signer-key}")
        private String signerKey;

        private final String[] PUBLIC_ENDPOINTS = {
                        "/auth/**"
        };

        @Bean
        public PasswordEncoder passwordEncoder() {
                return new BCryptPasswordEncoder();
        }

        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
                http
                                .csrf(AbstractHttpConfigurer::disable)
                                .authorizeHttpRequests(request -> request
                                                // Public endpoints
                                                .requestMatchers(HttpMethod.POST, PUBLIC_ENDPOINTS).permitAll()

                                                // Admin only endpoints
                                                .requestMatchers(HttpMethod.GET, "/users")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.GET, "/users/{userId}")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.PUT, "/users/{userId}")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.DELETE, "/users/{userId}")
                                                .hasRole(UserEnum.ADMIN.name())

                                                // Authenticated users (all roles)
                                                .requestMatchers("/users/myinfo", "/users/myinfo/**").authenticated()
                                                .requestMatchers("/api/upload/**").authenticated()

                                                // All other requests need authentication
                                                .anyRequest().authenticated())
                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt
                                                                .decoder(jwtDecoder())
                                                                .jwtAuthenticationConverter(
                                                                                jwtAuthenticationConverter())));

                return http.build();
        }

        @Bean
        JwtAuthenticationConverter jwtAuthenticationConverter() {
                JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
                converter.setJwtGrantedAuthoritiesConverter(jwt -> {
                        String role = jwt.getClaim("role");
                        if (role == null)
                                return Collections.emptyList();
                        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
                });
                return converter;
        }

        @Bean
        JwtDecoder jwtDecoder() {
                SecretKeySpec secretKeySpec = new SecretKeySpec(
                                signerKey.getBytes(),
                                "HS512");
                return NimbusJwtDecoder.withSecretKey(secretKeySpec)
                                .macAlgorithm(MacAlgorithm.HS512)
                                .build();
        }
}
