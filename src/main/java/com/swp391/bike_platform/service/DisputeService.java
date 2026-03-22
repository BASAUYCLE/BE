package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.Dispute;
import com.swp391.bike_platform.entity.Order;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.DisputeStatus;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.OrderStatus;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.DisputeRepository;
import com.swp391.bike_platform.repository.FeedbackRepository;
import com.swp391.bike_platform.repository.OrderRepository;
import com.swp391.bike_platform.repository.UserRepository;
import com.swp391.bike_platform.request.CreateDisputeRequest;
import com.swp391.bike_platform.request.NoteRequest;
import com.swp391.bike_platform.request.UpdateShippingInfoRequest;
import com.swp391.bike_platform.response.DisputeResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.Wallet;
import com.swp391.bike_platform.enums.PostStatus;
import com.swp391.bike_platform.enums.TransactionType;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.repository.InspectionReportRepository;
import com.swp391.bike_platform.entity.InspectionReport;
import com.swp391.bike_platform.enums.UserEnum;

@Service
@RequiredArgsConstructor
@Slf4j
public class DisputeService {

    private final DisputeRepository disputeRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final SystemConfigService systemConfigService;
    private final CloudinaryService cloudinaryService;
    private final WalletService walletService;
    private final TransactionService transactionService;
    private final BicyclePostRepository bicyclePostRepository;
    private final FeedbackRepository feedbackRepository;
    private final InspectionReportRepository inspectionReportRepository;

    // ─────────────────── POST /disputes (BUYER MỞ DISPUTE) ───────────────────
    @Transactional
    public DisputeResponse createDispute(Long buyerId, CreateDisputeRequest request) throws IOException {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        if (!order.getBuyer().getUserId().equals(buyerId)) {
            throw new AppException(ErrorCode.NOT_ORDER_BUYER);
        }

        String status = order.getOrderStatus();
        boolean isShipping = OrderStatus.SHIPPING.name().equals(status);
        boolean isDelivered = OrderStatus.DELIVERED.name().equals(status);

        if (!isShipping && !isDelivered) {
            throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
        }

        boolean isDepositOrder = order.getDepositAmount().compareTo(order.getTotalPrice()) < 0;

        if (isShipping) {
            // Đơn đang giao (SHIPPING): Chỉ dành cho đơn Cọc (do từ chối nhận hàng bằng
            // miệng với shipper)
            if (!isDepositOrder) {
                throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
            }
        } else if (isDelivered) {
            // Đơn đã giao (DELIVERED): Đơn Cọc KHÔNG ĐƯỢC KHIẾU NẠI nữa (do đã hoàn tất trả
            // COD ngoài đời)
            if (isDepositOrder) {
                throw new AppException(ErrorCode.CANNOT_DISPUTE_COD_RECEIPT);
            }
        }

        if (feedbackRepository.existsByOrder_OrderId(order.getOrderId())) {
            throw new AppException(ErrorCode.ORDER_ALREADY_REVIEWED);
        }

        // Validate 3 days (Dispute Window)
        LocalDateTime baseTime = isDelivered ? order.getDeliveredAt() : order.getShippedAt();
        if (baseTime == null) {
            baseTime = LocalDateTime.now(); // Fallback an toàn
        }

        int disputeWindowDays = systemConfigService.getDisputeWindowDays();
        LocalDateTime deadline = baseTime.plusDays(disputeWindowDays);

        if (LocalDateTime.now().isAfter(deadline)) {
            throw new AppException(ErrorCode.DISPUTE_WINDOW_EXPIRED);
        }

        // Check if dispute already exists
        if (disputeRepository.existsByOrder_OrderIdAndStatusNot(order.getOrderId(), DisputeStatus.REJECTED.name())) {
            throw new AppException(ErrorCode.ORDER_ALREADY_EXISTS);
        }

        // Upload proof image to Cloudinary
        if (request.getProofImage() == null || request.getProofImage().isEmpty()) {
            throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
        }
        String imageUrl = cloudinaryService.uploadImage(request.getProofImage());

        Dispute dispute = Dispute.builder()
                .order(order)
                .buyer(order.getBuyer())
                .status(DisputeStatus.OPEN.name())
                .reason(request.getReason())
                .proofImages(imageUrl)
                .build();

        dispute = disputeRepository.save(dispute);

        order.setOrderStatus(OrderStatus.DISPUTED.name());
        orderRepository.save(order);

        log.info("Dispute #{} opened for order #{} by buyer {}", dispute.getDisputeId(), order.getOrderId(), buyerId);
        return toResponse(dispute);
    }

    // ─────────────────── GET /disputes/{id} ───────────────────
    public DisputeResponse getDisputeById(Long disputeId, Long userId) {
        Dispute dispute = findDisputeById(disputeId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        // Admin can view all disputes
        if (UserEnum.ADMIN.equals(user.getRole())) {
            return toResponse(dispute);
        }

        // Buyer or Seller of the order can view
        Long buyerId = dispute.getBuyer().getUserId();
        Long sellerId = dispute.getOrder().getPost().getSeller().getUserId();
        if (buyerId.equals(userId) || sellerId.equals(userId)) {
            return toResponse(dispute);
        }

        // Inspector: only if they approved the post
        if (UserEnum.INSPECTOR.equals(user.getRole())) {
            Long postId = dispute.getOrder().getPost().getPostId();
            InspectionReport report = inspectionReportRepository.findByPost_PostId(postId)
                    .orElseThrow(() -> new AppException(ErrorCode.INSPECTION_REPORT_NOT_FOUND));
            if (report.getInspector().getUserId().equals(userId)) {
                return toResponse(dispute);
            }
            throw new AppException(ErrorCode.UNAUTHORIZED_INSPECTOR);
        }

        throw new AppException(ErrorCode.UNAUTHORIZED);
    }

    // ─────────────────── GET /disputes/my-disputes ───────────────────
    public List<DisputeResponse> getMyDisputes(Long userId) {
        return disputeRepository.findByBuyerOrSeller(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // ─────────────────── PUT /disputes/{id}/inspector-note ───────────────────
    @Transactional
    public DisputeResponse addInspectorNote(Long disputeId, Long inspectorId, NoteRequest request) {
        Dispute dispute = findDisputeById(disputeId);

        // Only allow adding/updating note when dispute is OPEN
        if (!DisputeStatus.OPEN.name().equals(dispute.getStatus())) {
            throw new AppException(ErrorCode.INVALID_DISPUTE_STATUS);
        }

        // Verify inspector is the one who approved the post
        Long postId = dispute.getOrder().getPost().getPostId();
        InspectionReport report = inspectionReportRepository.findByPost_PostId(postId)
                .orElseThrow(() -> new AppException(ErrorCode.INSPECTION_REPORT_NOT_FOUND));

        if (!report.getInspector().getUserId().equals(inspectorId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED_INSPECTOR);
        }

        // Auto-assign inspector to dispute if not yet assigned
        if (dispute.getInspector() == null) {
            User inspector = userRepository.findById(inspectorId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
            dispute.setInspector(inspector);
        }

        dispute.setInspectorNote(request.getNote());
        dispute.setStatus(DisputeStatus.REVIEWING.name());

        dispute = disputeRepository.save(dispute);
        log.info("Inspector {} added note to Dispute #{}", inspectorId, disputeId);
        return toResponse(dispute);
    }

    // ─────────────────── PUT /disputes/admin/{id}/approve ───────────────────
    @Transactional
    public DisputeResponse approveDispute(Long disputeId, Long adminId, NoteRequest request) {
        Dispute dispute = findDisputeById(disputeId);

        String status = dispute.getStatus();
        if (!DisputeStatus.OPEN.name().equals(status) && !DisputeStatus.REVIEWING.name().equals(status)) {
            throw new AppException(ErrorCode.INVALID_DISPUTE_STATUS);
        }

        dispute.setStatus(DisputeStatus.APPROVED.name());
        if (request != null && request.getNote() != null) {
            dispute.setAdminNote(request.getNote());
        }
        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
        dispute.setResolvedBy(admin);

        dispute = disputeRepository.save(dispute);
        log.info("Admin {} approved Dispute #{}", adminId, disputeId);
        return toResponse(dispute);
    }

    // ─────────────────── PUT /disputes/admin/{id}/reject ───────────────────
    @Transactional
    public DisputeResponse rejectDisputeByAdmin(Long disputeId, Long adminId, NoteRequest request) {
        Dispute dispute = findDisputeById(disputeId);

        String status = dispute.getStatus();
        if (DisputeStatus.RESOLVED.name().equals(status) || DisputeStatus.REJECTED.name().equals(status)) {
            throw new AppException(ErrorCode.INVALID_DISPUTE_STATUS);
        }

        if (request != null && request.getNote() != null) {
            dispute.setAdminNote(request.getNote());
        }
        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
        dispute.setResolvedBy(admin);

        rejectDispute(dispute);
        log.info("Admin {} rejected Dispute #{}", adminId, disputeId);
        return toResponse(dispute);
    }

    // ─────────────────── PUT /disputes/{id}/shipping-info ───────────────────
    @Transactional
    public DisputeResponse updateShippingInfo(Long disputeId, Long buyerId,
            UpdateShippingInfoRequest request) {
        Dispute dispute = findDisputeById(disputeId);

        if (!dispute.getBuyer().getUserId().equals(buyerId)) {
            throw new AppException(ErrorCode.NOT_DISPUTE_BUYER);
        }
        if (!DisputeStatus.APPROVED.name().equals(dispute.getStatus())) {
            throw new AppException(ErrorCode.INVALID_DISPUTE_STATUS);
        }

        dispute.setShippingProvider(request.getShippingProvider());
        dispute.setTrackingCode(request.getTrackingCode());
        dispute.setShippingReceiptUrl(request.getShippingReceiptUrl());
        dispute.setReturnShippedAt(LocalDateTime.now());
        dispute.setStatus(DisputeStatus.RETURN_SHIPPED.name());

        dispute = disputeRepository.save(dispute);
        log.info("Buyer {} uploaded shipping info for Dispute #{}", buyerId, disputeId);
        return toResponse(dispute);
    }

    // ─────────────── PUT /disputes/{id}/confirm-return-receipt ───────────────
    @Transactional
    public DisputeResponse confirmReturnReceipt(Long disputeId, Long sellerId) {
        Dispute dispute = findDisputeById(disputeId);

        Long orderSellerId = dispute.getOrder().getPost().getSeller().getUserId();
        if (!orderSellerId.equals(sellerId)) {
            throw new AppException(ErrorCode.NOT_DISPUTE_SELLER);
        }
        if (!DisputeStatus.RETURN_SHIPPED.name().equals(dispute.getStatus())) {
            throw new AppException(ErrorCode.INVALID_DISPUTE_STATUS);
        }

        resolveDispute(dispute);
        log.info("Seller {} confirmed return receipt for Dispute #{}", sellerId, disputeId);
        return toResponse(dispute);
    }

    // ─────────────────── AUTOMATION SCHEDULER LOGIC ───────────────────

    @Transactional
    public void autoCloseUnshippedDisputes() {
        int days = systemConfigService.getAutoCloseUnshippedDisputeDays();
        LocalDateTime deadline = LocalDateTime.now().minusDays(days);

        List<Dispute> disputes = disputeRepository.findByStatusAndUpdatedAtBefore(DisputeStatus.APPROVED.name(),
                deadline);
        for (Dispute d : disputes) {
            rejectDispute(d);
            log.info("Auto closed unshipped dispute #{} after {} days", d.getDisputeId(), days);
        }
    }

    @Transactional
    public void autoRefundShippedDisputes() {
        int days = systemConfigService.getAutoRefundShippedDisputeDays();
        LocalDateTime deadline = LocalDateTime.now().minusDays(days);

        List<Dispute> disputes = disputeRepository
                .findByStatusAndReturnShippedAtBefore(DisputeStatus.RETURN_SHIPPED.name(), deadline);
        for (Dispute d : disputes) {
            resolveDispute(d);
            log.info("Auto refunded shipped dispute #{} after {} days", d.getDisputeId(), days);
        }
    }

    // ─────────────────── HELPERS ───────────────────
    public void rejectDispute(Dispute dispute) {
        dispute.setStatus(DisputeStatus.REJECTED.name());
        dispute.setResolvedAt(LocalDateTime.now());
        disputeRepository.save(dispute);

        Order order = dispute.getOrder();
        order.setOrderStatus(OrderStatus.COMPLETED.name());
        orderRepository.save(order);

        // Transfer money to Seller
        Long sellerId = order.getPost().getSeller().getUserId();
        Wallet sellerWallet = walletService.getOrCreateWallet(sellerId);
        BigDecimal sellerAmount = OrderStatus.PAID.name().equals(order.getOrderStatus())
                ? order.getTotalPrice()
                : order.getDepositAmount();

        walletService.addBalance(sellerWallet.getWalletId(), sellerAmount);
        transactionService.createOrderTransaction(
                sellerWallet, sellerWallet.getUser(), order.getPost(),
                TransactionType.PURCHASE, sellerAmount,
                formatDescription("+", sellerAmount,
                        "Nhận tiền bán đơn #" + order.getOrderId() + " (Tranh chấp bị từ chối)"));

        // Update post status to SOLD
        BicyclePost post = order.getPost();
        post.setPostStatus(PostStatus.SOLD.name());
        bicyclePostRepository.save(post);
    }

    public void resolveDispute(Dispute dispute) {
        dispute.setStatus(DisputeStatus.RESOLVED.name());
        dispute.setResolvedAt(LocalDateTime.now());
        disputeRepository.save(dispute);

        Order order = dispute.getOrder();
        order.setOrderStatus(OrderStatus.CANCELLED.name());
        orderRepository.save(order);

        // Refund money to Buyer
        Long buyerId = order.getBuyer().getUserId();
        Wallet buyerWallet = walletService.getOrCreateWallet(buyerId);
        BigDecimal refundAmount = OrderStatus.PAID.name().equals(order.getOrderStatus())
                ? order.getTotalPrice()
                : order.getDepositAmount();

        walletService.addBalance(buyerWallet.getWalletId(), refundAmount);
        transactionService.createOrderTransaction(
                buyerWallet, buyerWallet.getUser(), order.getPost(),
                TransactionType.DISPUTE_REFUND, refundAmount,
                formatDescription("+", refundAmount, "Hoàn tiền tranh chấp đơn #" + order.getOrderId()));

        // Restore post to AVAILABLE
        BicyclePost post = order.getPost();
        post.setPostStatus(PostStatus.AVAILABLE.name());
        bicyclePostRepository.save(post);
    }

    private String formatDescription(String prefix, BigDecimal amount, String label) {
        DecimalFormat df = new DecimalFormat("#,###");
        return prefix + df.format(amount) + " VND - " + label;
    }

    private Dispute findDisputeById(Long disputeId) {
        return disputeRepository.findById(disputeId)
                .orElseThrow(() -> new AppException(ErrorCode.DISPUTE_NOT_FOUND));
    }

    private DisputeResponse toResponse(Dispute dispute) {
        DisputeResponse.DisputeResponseBuilder builder = DisputeResponse.builder()
                .disputeId(dispute.getDisputeId())
                .orderId(dispute.getOrder().getOrderId())
                .postTitle(dispute.getOrder().getPost().getBicycleName())
                .buyerId(dispute.getBuyer().getUserId())
                .buyerName(dispute.getBuyer().getFullName())
                .sellerId(dispute.getOrder().getPost().getSeller().getUserId())
                .sellerName(dispute.getOrder().getPost().getSeller().getFullName())
                .status(dispute.getStatus())
                .reason(dispute.getReason())
                .proofImages(dispute.getProofImages() != null && !dispute.getProofImages().isEmpty()
                        ? List.of(dispute.getProofImages().split(","))
                        : null)
                .inspectorNote(dispute.getInspectorNote())
                .adminNote(dispute.getAdminNote())
                .shippingProvider(dispute.getShippingProvider())
                .trackingCode(dispute.getTrackingCode())
                .shippingReceiptUrl(dispute.getShippingReceiptUrl())
                .returnShippedAt(dispute.getReturnShippedAt())
                .resolvedAt(dispute.getResolvedAt())
                .createdAt(dispute.getCreatedAt())
                .updatedAt(dispute.getUpdatedAt());

        if (dispute.getInspector() != null) {
            builder.inspectorId(dispute.getInspector().getUserId());
        }
        return builder.build();
    }
}
