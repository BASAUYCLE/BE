package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.TopUpRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.WalletResponse;
import com.swp391.bike_platform.service.TransactionService;
import com.swp391.bike_platform.service.UserService;
import com.swp391.bike_platform.service.WalletService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/wallet")
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;
    private final TransactionService transactionService;
    private final UserService userService;

    /**
     * GET /wallet — Xem ví (tự tạo nếu chưa có)
     */
    @GetMapping
    public ApiResponse<WalletResponse> getWallet(@AuthenticationPrincipal Jwt jwt) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        return ApiResponse.<WalletResponse>builder()
                .result(walletService.getWalletResponse(user.getUserId()))
                .build();
    }

    /**
     * POST /wallet/top-up — Nạp tiền → trả VNPay payment URL
     */
    @PostMapping("/top-up")
    public ApiResponse<String> topUp(@AuthenticationPrincipal Jwt jwt,
            @RequestBody TopUpRequest request,
            HttpServletRequest httpRequest) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        String ipAddress = getClientIp(httpRequest);
        String paymentUrl = transactionService.initiateTopUp(user.getUserId(), request.getAmount(), ipAddress);
        return ApiResponse.<String>builder()
                .result(paymentUrl)
                .message("Redirect to this URL to complete payment")
                .build();
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) {
            ip = request.getRemoteAddr();
        }
        return ip;
    }
}
