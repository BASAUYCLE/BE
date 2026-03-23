package com.swp391.bike_platform.response;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedbackResponse {
    private Long feedbackId;
    private Long orderId;
    private Long buyerId;
    private String buyerName;
    private String buyerAvatarUrl;
    private Long sellerId;
    private String sellerName;
    private String sellerAvatarUrl;
    private Long postId;
    private String postTitle;
    private Integer rating;
    private String comment;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
