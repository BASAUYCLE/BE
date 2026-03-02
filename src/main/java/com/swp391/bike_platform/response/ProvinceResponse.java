package com.swp391.bike_platform.response;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProvinceResponse {
    private String provinceCode;
    private String name;
    private String nameWithType;
}
