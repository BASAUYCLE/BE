package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.CreateOrderRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.OrderResponse;
import com.swp391.bike_platform.service.OrderService;
import com.swp391.bike_platform.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
public class OrderController {

        private final OrderService orderService;
        private final UserService userService;

        /**
         * POST /orders — Create a new order (deposit or full payment)
         */
        @PostMapping
        public ApiResponse<OrderResponse> createOrder(@AuthenticationPrincipal Jwt jwt,
                        @RequestBody CreateOrderRequest request) {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return ApiResponse.<OrderResponse>builder()
                                .result(orderService.createOrder(user.getUserId(), request))
                                .message("Order created successfully")
                                .build();
        }

        /**
         * GET /orders/{id} — Get order detail
         */
        @GetMapping("/{id}")
        public ApiResponse<OrderResponse> getOrder(@PathVariable Long id) {
                return ApiResponse.<OrderResponse>builder()
                                .result(orderService.getOrderById(id))
                                .build();
        }

        /**
         * GET /orders/my-orders — Get buyer's purchase history
         */
        @GetMapping("/my-orders")
        public ApiResponse<List<OrderResponse>> getMyOrders(@AuthenticationPrincipal Jwt jwt) {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return ApiResponse.<List<OrderResponse>>builder()
                                .result(orderService.getMyOrders(user.getUserId()))
                                .build();
        }

        /**
         * GET /orders/my-sales — Get seller's sales history
         */
        @GetMapping("/my-sales")
        public ApiResponse<List<OrderResponse>> getMySales(@AuthenticationPrincipal Jwt jwt) {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return ApiResponse.<List<OrderResponse>>builder()
                                .result(orderService.getMySales(user.getUserId()))
                                .build();
        }

        /**
         * PUT /orders/{id}/shipping — Confirm shipping with proof image (PAID →
         * SHIPPING)
         */
        @PutMapping("/{id}/shipping")
        public ApiResponse<OrderResponse> confirmShipping(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id,
                        @RequestParam(required = false) String shippingMethod,
                        @RequestParam(required = false) String shippingTrackingNumber,
                        @RequestPart MultipartFile proofImage) throws IOException {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return ApiResponse.<OrderResponse>builder()
                                .result(orderService.confirmShipping(id, user.getUserId(),
                                                shippingMethod, shippingTrackingNumber, proofImage))
                                .message("Shipping confirmed successfully")
                                .build();
        }

        /**
         * PUT /orders/{id}/confirm-delivery — Buyer confirms delivery (SHIPPING →
         * COMPLETED)
         */
        @PutMapping("/{id}/confirm-delivery")
        public ApiResponse<OrderResponse> confirmDelivery(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id) {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return ApiResponse.<OrderResponse>builder()
                                .result(orderService.confirmDelivery(id, user.getUserId()))
                                .message("Delivery confirmed successfully")
                                .build();
        }

        /**
         * PUT /orders/{id}/cancel — Cancel order
         * Buyer cancel = loses deposit; Seller cancel = full refund to buyer
         */
        @PutMapping("/{id}/cancel")
        public ApiResponse<OrderResponse> cancelOrder(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id) {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return ApiResponse.<OrderResponse>builder()
                                .result(orderService.cancelOrder(id, user.getUserId()))
                                .message("Order cancelled")
                                .build();
        }
}
