package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.*;
import com.swp391.bike_platform.enums.*;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.repository.OrderRepository;
import com.swp391.bike_platform.repository.UserAddressRepository;
import com.swp391.bike_platform.repository.DisputeRepository;
import com.swp391.bike_platform.request.CreateOrderRequest;
import com.swp391.bike_platform.response.OrderResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final BicyclePostRepository bicyclePostRepository;
    private final UserAddressRepository userAddressRepository;
    private final WalletService walletService;
    private final SystemConfigService systemConfigService;
    private final TransactionService transactionService;
    private final CloudinaryService cloudinaryService;
    private final DisputeRepository disputeRepository;

    private static final List<String> ACTIVE_STATUSES = Arrays.asList(
            OrderStatus.DEPOSITED.name(),
            OrderStatus.PAID.name(),
            OrderStatus.SHIPPING.name());

    // ─────────────────── CREATE ORDER ───────────────────

    @Transactional
    public OrderResponse createOrder(Long buyerId, CreateOrderRequest request) {
        BicyclePost post = bicyclePostRepository.findById(request.getPostId())
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));

        // Cannot buy own post
        if (post.getSeller().getUserId().equals(buyerId)) {
            throw new AppException(ErrorCode.CANNOT_ORDER_OWN_POST);
        }

        // Post must be AVAILABLE
        if (!PostStatus.AVAILABLE.name().equals(post.getPostStatus())) {
            throw new AppException(ErrorCode.POST_NOT_AVAILABLE_FOR_ORDER);
        }

        // No active order for this post
        List<Order> activeOrders = orderRepository.findByPostIdAndStatuses(post.getPostId(), ACTIVE_STATUSES);
        if (!activeOrders.isEmpty()) {
            throw new AppException(ErrorCode.ORDER_ALREADY_EXISTS);
        }

        // Get buyer wallet
        Wallet buyerWallet = walletService.getOrCreateWallet(buyerId);
        BigDecimal totalPrice = post.getPrice();

        // Get address if provided
        UserAddress address = null;
        if (request.getAddressId() != null) {
            address = userAddressRepository.findById(request.getAddressId())
                    .orElseThrow(() -> new AppException(ErrorCode.ADDRESS_NOT_FOUND));
        }

        Order order;

        if (request.isPayFull()) {
            // Full payment
            walletService.deductBalance(buyerWallet.getWalletId(), totalPrice);

            order = Order.builder()
                    .post(post)
                    .buyer(buyerWallet.getUser())
                    .address(address)
                    .totalPrice(totalPrice)
                    .depositAmount(totalPrice)
                    .orderStatus(OrderStatus.PAID.name())
                    .build();
            order = orderRepository.save(order);

            // Create transaction
            transactionService.createOrderTransaction(
                    buyerWallet, buyerWallet.getUser(), post,
                    TransactionType.PURCHASE, totalPrice,
                    formatDescription("-", totalPrice, "Payment for Order #" + order.getOrderId()));
        } else {
            // Deposit only
            BigDecimal depositRate = systemConfigService.getDepositRate()
                    .divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
            BigDecimal depositAmount = totalPrice.multiply(depositRate).setScale(2, RoundingMode.HALF_UP);

            walletService.deductBalance(buyerWallet.getWalletId(), depositAmount);

            order = Order.builder()
                    .post(post)
                    .buyer(buyerWallet.getUser())
                    .address(address)
                    .totalPrice(totalPrice)
                    .depositAmount(depositAmount)
                    .orderStatus(OrderStatus.DEPOSITED.name())
                    .build();
            order = orderRepository.save(order);

            // Create transaction
            transactionService.createOrderTransaction(
                    buyerWallet, buyerWallet.getUser(), post,
                    TransactionType.DEPOSIT, depositAmount,
                    formatDescription("-", depositAmount, "Deposit for Order #" + order.getOrderId()));
        }

        // Update post status
        if (request.isPayFull()) {
            post.setPostStatus(PostStatus.PROCESSING.name());
        } else {
            post.setPostStatus(PostStatus.DEPOSITED.name());
        }
        bicyclePostRepository.save(post);

        log.info("Order #{} created by buyer {} for post {}", order.getOrderId(), buyerId, post.getPostId());
        return toResponse(order);
    }

    // ─────────────────── CONFIRM SHIPPING ───────────────────

    @Transactional
    public OrderResponse confirmShipping(Long orderId, Long sellerId,
            String shippingMethod, String trackingNumber,
            MultipartFile proofImage) throws IOException {
        Order order = findOrderById(orderId);
        validateSeller(order, sellerId);

        if (!OrderStatus.PAID.name().equals(order.getOrderStatus())
                && !OrderStatus.DEPOSITED.name().equals(order.getOrderStatus())) {
            throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
        }

        // Upload proof image to Cloudinary (required)
        if (proofImage == null || proofImage.isEmpty()) {
            throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
        }
        String imageUrl = cloudinaryService.uploadImage(proofImage);
        order.setProofImage(imageUrl);

        order.setShippingMethod(shippingMethod);
        order.setShippingTrackingNumber(trackingNumber);
        order.setOrderStatus(OrderStatus.SHIPPING.name());
        order.setShippedAt(LocalDateTime.now());
        orderRepository.save(order);

        log.info("Order #{} shipped by seller {}", orderId, sellerId);
        return toResponse(order);
    }

    // ─────────────────── CONFIRM DELIVERY ───────────────────

    @Transactional
    public OrderResponse confirmDelivery(Long orderId, Long buyerId) {
        Order order = findOrderById(orderId);
        validateBuyer(order, buyerId);

        if (!OrderStatus.SHIPPING.name().equals(order.getOrderStatus())) {
            throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
        }

        order.setDeliveredAt(LocalDateTime.now());

        boolean isDepositOrder = order.getDepositAmount().compareTo(order.getTotalPrice()) < 0;

        if (isDepositOrder) {
            // Đơn Deposited: SHIPPING -> COMPLETED luôn (như user yêu cầu)
            completeOrder(order); // Hàm này tự set status = COMPLETED và save
        } else {
            // Đơn Full Paid: SHIPPING -> DELIVERED (đợi Dispute hoặc xác nhận đơn)
            order.setOrderStatus(OrderStatus.DELIVERED.name());
            orderRepository.save(order);
        }

        log.info("Order #{} delivery confirmed by buyer {}", orderId, buyerId);
        return toResponse(order);
    }

    @Transactional
    public OrderResponse completeOrderManually(Long orderId, Long buyerId) {
        Order order = findOrderById(orderId);
        validateBuyer(order, buyerId);

        boolean isDepositOrder = order.getDepositAmount().compareTo(order.getTotalPrice()) < 0;

        if (isDepositOrder) {
            // Đối với luồng Deposited: Nút "Xác nhận đơn" được bấm ngay lúc SHIPPING (hoặc
            // DELIVERED nếu lỡ auto)
            if (!OrderStatus.SHIPPING.name().equals(order.getOrderStatus())
                    && !OrderStatus.DELIVERED.name().equals(order.getOrderStatus())) {
                throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
            }
        } else {
            // Đối với luồng Full Paid: Nút "Xác nhận đơn" chỉ hiện khi đã lấy hàng xong
            // (DELIVERED)
            if (!OrderStatus.DELIVERED.name().equals(order.getOrderStatus())) {
                throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
            }
        }

        // Bỏ qua dispute window -> chuyển thẳng COMPLETED và nhả tiền
        completeOrder(order);

        log.info("Order #{} manually confirmed as completed by buyer {}", orderId, buyerId);
        return toResponse(order);
    }

    // ─────────────────── PAY REMAINING ───────────────────

    @Transactional
    public OrderResponse payRemaining(Long orderId, Long buyerId) {
        Order order = findOrderById(orderId);
        validateBuyer(order, buyerId);

        if (!OrderStatus.DEPOSITED.name().equals(order.getOrderStatus())) {
            throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
        }

        BigDecimal remaining = order.getTotalPrice().subtract(order.getDepositAmount());
        Wallet buyerWallet = walletService.getOrCreateWallet(buyerId);
        walletService.deductBalance(buyerWallet.getWalletId(), remaining);

        // Create transaction
        transactionService.createOrderTransaction(
                buyerWallet, buyerWallet.getUser(), order.getPost(),
                TransactionType.PAY_REMAINING, remaining,
                formatDescription("-", remaining, "Remaining balance payment for Order #" + orderId));

        order.setOrderStatus(OrderStatus.PAID.name());
        order.setDepositAmount(order.getTotalPrice()); // Update deposit as platform now holds full payment
        orderRepository.save(order);

        log.info("Order #{} fully paid by buyer {}", orderId, buyerId);
        return toResponse(order);
    }

    // ─────────────────── CANCEL ORDER ───────────────────

    @Transactional
    public OrderResponse cancelOrder(Long orderId, Long userId) {
        Order order = findOrderById(orderId);
        Long buyerId = order.getBuyer().getUserId();
        Long sellerId = order.getPost().getSeller().getUserId();

        boolean isBuyer = buyerId.equals(userId);
        boolean isSeller = sellerId.equals(userId);

        if (!isBuyer && !isSeller) {
            throw new AppException(ErrorCode.NOT_ORDER_BUYER);
        }

        String status = order.getOrderStatus();

        // Only allow cancel for DEPOSITED, PAID (NOT SHIPPING)
        if (!OrderStatus.DEPOSITED.name().equals(status)
                && !OrderStatus.PAID.name().equals(status)) {
            throw new AppException(ErrorCode.INVALID_ORDER_STATUS);
        }

        if (OrderStatus.PAID.name().equals(status)) {
            // Trường hợp 1: Bank Full (Đơn đã trả 100% - PAID)
            // Buyer/Seller hủy -> Hoàn 100% tiền lại vào ví Buyer. Seller không nhận được
            // gì.
            BigDecimal refundAmount = order.getTotalPrice();
            Wallet buyerWallet = walletService.getOrCreateWallet(buyerId);
            walletService.addBalance(buyerWallet.getWalletId(), refundAmount);

            transactionService.createOrderTransaction(
                    buyerWallet, buyerWallet.getUser(), order.getPost(),
                    TransactionType.REFUND, refundAmount,
                    formatDescription("+", refundAmount, "Refund for Order #" + orderId));

            log.info("Order #{} cancelled (PAID) by {} {} — refunded full {} to buyer", orderId,
                    isBuyer ? "buyer" : "seller", userId, refundAmount);

        } else if (OrderStatus.DEPOSITED.name().equals(status)) {
            // Trường hợp 2: Đặt cọc (Đơn chỉ cọc - DEPOSITED)
            BigDecimal depositAmount = order.getDepositAmount();

            if (isBuyer) {
                // Buyer hủy: Buyer mất cọc. Tiền cọc được chuyển thẳng vào ví Seller.
                Wallet sellerWallet = walletService.getOrCreateWallet(sellerId);
                walletService.addBalance(sellerWallet.getWalletId(), depositAmount);

                transactionService.createOrderTransaction(
                        sellerWallet, sellerWallet.getUser(), order.getPost(),
                        TransactionType.REFUND, depositAmount,
                        formatDescription("+", depositAmount,
                                "Deposit received for Order #" + orderId + " (Buyer cancelled)"));

                log.info("Order #{} cancelled (DEPOSITED) by buyer {} — deposit {} transferred to seller", orderId,
                        userId, depositAmount);
            } else {
                // Seller hủy: Hoàn lại 100% tiền cọc vào ví Buyer. Seller không nhận được gì.
                Wallet buyerWallet = walletService.getOrCreateWallet(buyerId);
                walletService.addBalance(buyerWallet.getWalletId(), depositAmount);

                transactionService.createOrderTransaction(
                        buyerWallet, buyerWallet.getUser(), order.getPost(),
                        TransactionType.REFUND, depositAmount,
                        formatDescription("+", depositAmount, "Refund for Order #" + orderId + " (Seller cancelled)"));

                log.info("Order #{} cancelled (DEPOSITED) by seller {} — deposit {} refunded to buyer", orderId, userId,
                        depositAmount);
            }
        }

        order.setOrderStatus(OrderStatus.CANCELLED.name());
        orderRepository.save(order);

        // Restore post to AVAILABLE
        BicyclePost post = order.getPost();
        post.setPostStatus(PostStatus.AVAILABLE.name());
        bicyclePostRepository.save(post);

        return toResponse(order);
    }

    // ─────────────────── AUTO CONFIRM ───────────────────

    @Transactional
    public void autoConfirmOrders() {
        int autoConfirmDays = systemConfigService.getAutoConfirmDays();
        LocalDateTime cutoff = LocalDateTime.now().minusDays(autoConfirmDays);

        List<Order> orders = orderRepository.findByStatusAndShippedAtBefore(
                OrderStatus.SHIPPING.name(), cutoff);

        for (Order order : orders) {
            order.setOrderStatus(OrderStatus.DELIVERED.name());
            order.setDeliveredAt(LocalDateTime.now());
            orderRepository.save(order);
            log.info("Order #{} auto-delivered (shipping confirmed) after {} days", order.getOrderId(),
                    autoConfirmDays);
        }

        if (!orders.isEmpty()) {
            log.info("Auto-confirmed shipping for {} orders", orders.size());
        }
    }

    @Transactional
    public void autoCompleteDeliveredOrders() {
        int disputeWindowDays = systemConfigService.getDisputeWindowDays();
        LocalDateTime cutoff = LocalDateTime.now().minusDays(disputeWindowDays);

        List<Order> orders = orderRepository.findByStatusAndDeliveredAtBefore(
                OrderStatus.DELIVERED.name(), cutoff);

        for (Order order : orders) {
            boolean hasActiveDispute = disputeRepository.existsByOrder_OrderIdAndStatusNot(
                    order.getOrderId(), DisputeStatus.REJECTED.name());
            if (!hasActiveDispute) {
                completeOrder(order);
                log.info("Order #{} auto-completed after {} days of delivery without dispute", order.getOrderId(),
                        disputeWindowDays);
            }
        }
    }

    // ─────────────────── QUERIES ───────────────────

    public OrderResponse getOrderById(Long orderId) {
        return toResponse(findOrderById(orderId));
    }

    public List<OrderResponse> getMyOrders(Long buyerId) {
        return orderRepository.findByBuyer_UserIdOrderByCreatedAtDesc(buyerId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<OrderResponse> getMySales(Long sellerId) {
        return orderRepository.findBySellerId(sellerId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // ─────────────────── HELPERS ───────────────────

    public void completeOrder(Order order) {
        // Transfer money to seller wallet based on payment type
        // The exact amount platform holds is in depositAmount
        Long sellerId = order.getPost().getSeller().getUserId();
        Wallet sellerWallet = walletService.getOrCreateWallet(sellerId);

        BigDecimal sellerAmount = order.getDepositAmount();

        walletService.addBalance(sellerWallet.getWalletId(), sellerAmount);

        transactionService.createOrderTransaction(
                sellerWallet, sellerWallet.getUser(), order.getPost(),
                TransactionType.RELEASE_MONEY, sellerAmount,
                formatDescription("+", sellerAmount,
                        "Sales proceeds for Order #" + order.getOrderId()));

        order.setOrderStatus(OrderStatus.COMPLETED.name());
        orderRepository.save(order);

        // Update post status to SOLD
        BicyclePost post = order.getPost();
        post.setPostStatus(PostStatus.SOLD.name());
        bicyclePostRepository.save(post);
    }

    private Order findOrderById(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));
    }

    private void validateBuyer(Order order, Long userId) {
        if (!order.getBuyer().getUserId().equals(userId)) {
            throw new AppException(ErrorCode.NOT_ORDER_BUYER);
        }
    }

    private void validateSeller(Order order, Long userId) {
        if (!order.getPost().getSeller().getUserId().equals(userId)) {
            throw new AppException(ErrorCode.NOT_ORDER_SELLER);
        }
    }

    private String formatDescription(String prefix, BigDecimal amount, String label) {
        DecimalFormat df = new DecimalFormat("#,###");
        return prefix + df.format(amount) + " VND - " + label;
    }

    private OrderResponse toResponse(Order order) {
        OrderResponse.OrderResponseBuilder builder = OrderResponse.builder()
                .orderId(order.getOrderId())
                .postId(order.getPost().getPostId())
                .postTitle(order.getPost().getBicycleName())
                .buyerId(order.getBuyer().getUserId())
                .buyerName(order.getBuyer().getFullName())
                .buyerAvatarUrl(order.getBuyer().getAvatarUrl())
                .sellerId(order.getPost().getSeller().getUserId())
                .sellerName(order.getPost().getSeller().getFullName())
                .sellerAvatarUrl(order.getPost().getSeller().getAvatarUrl())
                .totalPrice(order.getTotalPrice())
                .depositAmount(order.getDepositAmount())
                .orderStatus(order.getOrderStatus())
                .shippingMethod(order.getShippingMethod())
                .shippingTrackingNumber(order.getShippingTrackingNumber())
                .proofImage(order.getProofImage())
                .shippedAt(order.getShippedAt())
                .deliveredAt(order.getDeliveredAt())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt());

        if (order.getAddress() != null) {
            builder.addressId(order.getAddress().getAddressId())
                    .fullAddress(order.getAddress().getFullAddress());
        }

        return builder.build();
    }
}
