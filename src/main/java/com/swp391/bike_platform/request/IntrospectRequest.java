package com.swp391.bike_platform.request;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IntrospectRequest {
    private String token;
}
