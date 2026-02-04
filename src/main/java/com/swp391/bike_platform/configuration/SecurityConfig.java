package com.swp391.bike_platform.configuration;

import com.swp391.bike_platform.enums.UserEnum;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

        private final CorsConfigurationSource corsConfigurationSource;
        private final JwtDecoder jwtDecoder;
        private final JwtAuthenticationConverter jwtAuthenticationConverter;

        private final String[] PUBLIC_ENDPOINTS = {
                        "/auth/**"
        };

        public SecurityConfig(CorsConfigurationSource corsConfigurationSource,
                        JwtDecoder jwtDecoder,
                        JwtAuthenticationConverter jwtAuthenticationConverter) {
                this.corsConfigurationSource = corsConfigurationSource;
                this.jwtDecoder = jwtDecoder;
                this.jwtAuthenticationConverter = jwtAuthenticationConverter;
        }

        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
                http
                                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                                .csrf(AbstractHttpConfigurer::disable)
                                .authorizeHttpRequests(request -> request
                                                // Public endpoints
                                                .requestMatchers(HttpMethod.POST, PUBLIC_ENDPOINTS).permitAll()

                                                // Swagger / OpenAPI
                                                .requestMatchers("/v3/api-docs/**", "/swagger-ui/**",
                                                                "/swagger-ui.html")
                                                .permitAll()

                                                // Authenticated users (all roles) - PHẢI ĐẶT TRƯỚC /users/{userId}
                                                .requestMatchers("/users/myinfo", "/users/myinfo/**").authenticated()
                                                .requestMatchers("/api/upload/**").authenticated()

                                                // Admin only endpoints
                                                .requestMatchers("/admin/**")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.GET, "/users")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.GET, "/users/{userId}")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.PUT, "/users/{userId}")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.DELETE, "/users/{userId}")
                                                .hasRole(UserEnum.ADMIN.name())

                                                // Inspector only endpoints
                                                .requestMatchers("/inspection/**")
                                                .hasRole(UserEnum.INSPECTOR.name())

                                                // Brands - Public GET, Admin for CUD
                                                .requestMatchers(HttpMethod.GET, "/brands", "/brands/**").permitAll()
                                                .requestMatchers(HttpMethod.POST, "/brands")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.PUT, "/brands/**")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.DELETE, "/brands/**")
                                                .hasRole(UserEnum.ADMIN.name())

                                                // Categories - Public GET, Admin for CUD
                                                .requestMatchers(HttpMethod.GET, "/categories", "/categories/**")
                                                .permitAll()
                                                .requestMatchers(HttpMethod.POST, "/categories")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.PUT, "/categories/**")
                                                .hasRole(UserEnum.ADMIN.name())
                                                .requestMatchers(HttpMethod.DELETE, "/categories/**")
                                                .hasRole(UserEnum.ADMIN.name())

                                                // Posts - User's own posts endpoints (authenticated)
                                                .requestMatchers(HttpMethod.GET, "/posts/my-posts", "/posts/drafts")
                                                .authenticated()
                                                .requestMatchers(HttpMethod.POST, "/posts/draft").authenticated()

                                                // Posts - Public GET, Authenticated for CUD
                                                .requestMatchers(HttpMethod.GET, "/posts", "/posts/**").permitAll()
                                                .requestMatchers(HttpMethod.POST, "/posts").authenticated()
                                                .requestMatchers(HttpMethod.PUT, "/posts/**").authenticated()
                                                .requestMatchers(HttpMethod.DELETE, "/posts/**").authenticated()

                                                // Images - Public GET, Authenticated for CUD
                                                .requestMatchers(HttpMethod.GET, "/images", "/images/**").permitAll()
                                                .requestMatchers(HttpMethod.POST, "/images").authenticated()
                                                .requestMatchers(HttpMethod.PUT, "/images/**").authenticated()
                                                .requestMatchers(HttpMethod.DELETE, "/images/**").authenticated()

                                                // All other requests need authentication
                                                .anyRequest().authenticated())
                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt
                                                                .decoder(jwtDecoder)
                                                                .jwtAuthenticationConverter(
                                                                                jwtAuthenticationConverter)));

                return http.build();
        }
}
