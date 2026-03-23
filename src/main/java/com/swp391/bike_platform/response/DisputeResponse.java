package com.swp391.bike_platform.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class DisputeResponse {
    private Long disputeId;
    private Long orderId;
    private String postTitle;
    private Long buyerId;
    private String buyerName;
    private String buyerAvatarUrl;
    private Long sellerId;
    private String sellerName;
    private String sellerAvatarUrl;
    private Long inspectorId;
    private String inspectorName;
    private String inspectorEmail;
    private Long resolvedById;
    private String resolvedByName;
    private String resolvedByEmail;
    private String status;
    private String reason;
    private List<String> proofImages;
    private String inspectorNote;
    private String adminNote;
    private String shippingProvider;
    private String trackingCode;
    private String shippingReceiptUrl;
    private LocalDateTime returnShippedAt;
    private LocalDateTime resolvedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
