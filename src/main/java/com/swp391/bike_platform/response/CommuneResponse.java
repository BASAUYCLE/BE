package com.swp391.bike_platform.response;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommuneResponse {
    private String communeCode;
    private String name;
    private String nameWithType;
}
