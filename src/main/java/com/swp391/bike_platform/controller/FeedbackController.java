package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.FeedbackRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.FeedbackResponse;
import com.swp391.bike_platform.response.SellerRatingResponse;
import com.swp391.bike_platform.service.FeedbackService;
import com.swp391.bike_platform.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/feedbacks")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;
    private final UserService userService;

    /**
     * POST /feedbacks/orders/{orderId} — Create feedback for a completed order
     */
    @PostMapping("/orders/{orderId}")
    public ApiResponse<FeedbackResponse> createFeedback(@AuthenticationPrincipal Jwt jwt,
            @PathVariable Long orderId,
            @Valid @RequestBody FeedbackRequest request) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        return ApiResponse.<FeedbackResponse>builder()
                .result(feedbackService.createFeedback(orderId, user.getUserId(), request))
                .message("Feedback created successfully")
                .build();
    }

    /**
     * PUT /feedbacks/orders/{orderId} — Update existing feedback
     */
    @PutMapping("/orders/{orderId}")
    public ApiResponse<FeedbackResponse> updateFeedback(@AuthenticationPrincipal Jwt jwt,
            @PathVariable Long orderId,
            @Valid @RequestBody FeedbackRequest request) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        return ApiResponse.<FeedbackResponse>builder()
                .result(feedbackService.updateFeedback(orderId, user.getUserId(), request))
                .message("Feedback updated successfully")
                .build();
    }

    /**
     * DELETE /feedbacks/orders/{orderId} — Delete feedback
     */
    @DeleteMapping("/orders/{orderId}")
    public ApiResponse<Void> deleteFeedback(@AuthenticationPrincipal Jwt jwt,
            @PathVariable Long orderId) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        feedbackService.deleteFeedback(orderId, user.getUserId());
        return ApiResponse.<Void>builder()
                .message("Feedback deleted successfully")
                .build();
    }

    /**
     * GET /feedbacks/orders/{orderId} — Get feedback by order (public)
     */
    @GetMapping("/orders/{orderId}")
    public ApiResponse<FeedbackResponse> getFeedbackByOrder(@PathVariable Long orderId) {
        return ApiResponse.<FeedbackResponse>builder()
                .result(feedbackService.getFeedbackByOrderId(orderId))
                .build();
    }

    /**
     * GET /feedbacks/sellers/{sellerId} — Get all feedbacks of a seller (public)
     */
    @GetMapping("/sellers/{sellerId}")
    public ApiResponse<List<FeedbackResponse>> getFeedbacksBySeller(@PathVariable Long sellerId) {
        return ApiResponse.<List<FeedbackResponse>>builder()
                .result(feedbackService.getFeedbacksBySeller(sellerId))
                .build();
    }

    /**
     * GET /feedbacks/sellers/{sellerId}/rating — Get seller's average rating
     * (public)
     */
    @GetMapping("/sellers/{sellerId}/rating")
    public ApiResponse<SellerRatingResponse> getSellerRating(@PathVariable Long sellerId) {
        return ApiResponse.<SellerRatingResponse>builder()
                .result(feedbackService.getSellerRating(sellerId))
                .build();
    }

    /**
     * GET /feedbacks/posts/{postId} — Get all feedbacks for a post (public)
     */
    @GetMapping("/posts/{postId}")
    public ApiResponse<List<FeedbackResponse>> getFeedbacksByPost(@PathVariable Long postId) {
        return ApiResponse.<List<FeedbackResponse>>builder()
                .result(feedbackService.getFeedbacksByPost(postId))
                .build();
    }
}
