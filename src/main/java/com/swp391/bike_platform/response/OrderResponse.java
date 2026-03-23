package com.swp391.bike_platform.response;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {
    private Long orderId;
    private Long postId;
    private String postTitle;
    private Long buyerId;
    private String buyerName;
    private String buyerAvatarUrl;
    private Long sellerId;
    private String sellerName;
    private String sellerAvatarUrl;
    private Long addressId;
    private String fullAddress;
    private BigDecimal totalPrice;
    private BigDecimal depositAmount;
    private String orderStatus;
    private String shippingMethod;
    private String shippingTrackingNumber;
    private String proofImage;
    private LocalDateTime shippedAt;
    private LocalDateTime deliveredAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
