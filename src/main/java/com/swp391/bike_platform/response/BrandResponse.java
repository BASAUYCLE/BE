package com.swp391.bike_platform.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BrandResponse {
    private Long brandId;
    private String brandName;
    private String brandLogoUrl;
    private String brandOriginCountry;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
