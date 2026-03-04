package com.swp391.bike_platform.response;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemConfigResponse {
    private String key;
    private String value;
    private String description;
}
