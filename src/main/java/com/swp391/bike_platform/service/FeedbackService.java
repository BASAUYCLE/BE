package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.Feedback;
import com.swp391.bike_platform.entity.Order;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.OrderStatus;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.FeedbackRepository;
import com.swp391.bike_platform.repository.OrderRepository;
import com.swp391.bike_platform.repository.UserRepository;
import com.swp391.bike_platform.request.FeedbackRequest;
import com.swp391.bike_platform.response.FeedbackResponse;
import com.swp391.bike_platform.response.SellerRatingResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    // ─────────────────── CREATE ───────────────────

    @Transactional
    public FeedbackResponse createFeedback(Long orderId, Long buyerId, FeedbackRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        // Chỉ buyer của order mới được đánh giá
        if (!order.getBuyer().getUserId().equals(buyerId)) {
            throw new AppException(ErrorCode.NOT_ORDER_BUYER);
        }

        // Chỉ order COMPLETED mới được đánh giá
        if (!OrderStatus.COMPLETED.name().equals(order.getOrderStatus())) {
            throw new AppException(ErrorCode.ORDER_NOT_COMPLETED);
        }

        // Mỗi order chỉ được đánh giá 1 lần
        if (feedbackRepository.existsByOrder_OrderId(orderId)) {
            throw new AppException(ErrorCode.FEEDBACK_ALREADY_EXISTS);
        }

        Feedback feedback = Feedback.builder()
                .order(order)
                .buyer(order.getBuyer())
                .seller(order.getPost().getSeller())
                .post(order.getPost())
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        feedbackRepository.save(feedback);
        log.info("Feedback created for order #{} by buyer {}", orderId, buyerId);

        return toResponse(feedback);
    }

    // ─────────────────── UPDATE ───────────────────

    @Transactional
    public FeedbackResponse updateFeedback(Long orderId, Long buyerId, FeedbackRequest request) {
        Feedback feedback = feedbackRepository.findByOrder_OrderId(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.FEEDBACK_NOT_FOUND));

        // Chỉ buyer mới được sửa
        if (!feedback.getBuyer().getUserId().equals(buyerId)) {
            throw new AppException(ErrorCode.NOT_ORDER_BUYER);
        }

        feedback.setRating(request.getRating());
        feedback.setComment(request.getComment());
        feedbackRepository.save(feedback);

        log.info("Feedback updated for order #{} by buyer {}", orderId, buyerId);
        return toResponse(feedback);
    }

    // ─────────────────── DELETE ───────────────────

    @Transactional
    public void deleteFeedback(Long orderId, Long buyerId) {
        Feedback feedback = feedbackRepository.findByOrder_OrderId(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.FEEDBACK_NOT_FOUND));

        // Chỉ buyer mới được xóa
        if (!feedback.getBuyer().getUserId().equals(buyerId)) {
            throw new AppException(ErrorCode.NOT_ORDER_BUYER);
        }

        feedbackRepository.delete(feedback);
        log.info("Feedback deleted for order #{} by buyer {}", orderId, buyerId);
    }

    // ─────────────────── QUERY ───────────────────

    public FeedbackResponse getFeedbackByOrderId(Long orderId) {
        return toResponse(feedbackRepository.findByOrder_OrderId(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.FEEDBACK_NOT_FOUND)));
    }

    public List<FeedbackResponse> getFeedbacksBySeller(Long sellerId) {
        return feedbackRepository.findBySeller_UserIdOrderByCreatedAtDesc(sellerId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<FeedbackResponse> getFeedbacksByPost(Long postId) {
        return feedbackRepository.findByPost_PostIdOrderByCreatedAtDesc(postId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public SellerRatingResponse getSellerRating(Long sellerId) {
        User seller = userRepository.findById(sellerId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        Double avgRating = feedbackRepository.getAverageRatingBySellerId(sellerId);
        Long totalReviews = feedbackRepository.countBySellerId(sellerId);

        return SellerRatingResponse.builder()
                .sellerId(sellerId)
                .sellerName(seller.getFullName())
                .sellerAvatarUrl(seller.getAvatarUrl())
                .averageRating(avgRating != null ? Math.round(avgRating * 10.0) / 10.0 : 0.0)
                .totalReviews(totalReviews)
                .build();
    }

    // ─────────────────── MAPPER ───────────────────

    private FeedbackResponse toResponse(Feedback feedback) {
        return FeedbackResponse.builder()
                .feedbackId(feedback.getFeedbackId())
                .orderId(feedback.getOrder().getOrderId())
                .buyerId(feedback.getBuyer().getUserId())
                .buyerName(feedback.getBuyer().getFullName())
                .buyerAvatarUrl(feedback.getBuyer().getAvatarUrl())
                .sellerId(feedback.getSeller().getUserId())
                .sellerName(feedback.getSeller().getFullName())
                .sellerAvatarUrl(feedback.getSeller().getAvatarUrl())
                .postId(feedback.getPost().getPostId())
                .postTitle(feedback.getPost().getBicycleName())
                .rating(feedback.getRating())
                .comment(feedback.getComment())
                .createdAt(feedback.getCreatedAt())
                .updatedAt(feedback.getUpdatedAt())
                .build();
    }
}
