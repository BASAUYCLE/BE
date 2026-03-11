package com.swp391.bike_platform.response;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SellerRatingResponse {
    private Long sellerId;
    private String sellerName;
    private Double averageRating;
    private Long totalReviews;
}
