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
public class WishlistResponse {
    private Long wishlistId;
    private Long postId;
    private String bicycleName;
    private String brandName;
    private BigDecimal price;
    private String postStatus;
    private String thumbnailUrl;
    private LocalDateTime createdAt;
}
