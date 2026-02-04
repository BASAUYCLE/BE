package com.swp391.bike_platform.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BicyclePostSummaryResponse {
    private Long postId;
    private String bicycleName;
    private BigDecimal price;
    private String brandName;
    private String categoryName;
    private String size;
    private String postStatus;
    private String thumbnailUrl;
    private String sellerFullName;
    private LocalDateTime createdAt;
}
