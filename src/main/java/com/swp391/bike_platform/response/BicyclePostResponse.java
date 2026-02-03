package com.swp391.bike_platform.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BicyclePostResponse {
    private Long postId;

    // Seller info
    private Long sellerId;
    private String sellerFullName;
    private String sellerPhoneNumber;

    // Brand info
    private Long brandId;
    private String brandName;

    // Category info
    private Long categoryId;
    private String categoryName;

    // Bicycle info
    private String bicycleName;
    private String bicycleColor;
    private BigDecimal price;
    private String bicycleDescription;

    // Technical specs
    private String groupset;
    private String frameMaterial;
    private String brakeType;
    private String size;
    private Integer modelYear;

    // Status
    private String postStatus;

    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Images
    private List<BicycleImageResponse> images;
}
