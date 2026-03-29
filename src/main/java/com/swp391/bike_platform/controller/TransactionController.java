package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.WithdrawRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.TransactionResponse;
import com.swp391.bike_platform.service.TransactionService;
import com.swp391.bike_platform.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;
    private final UserService userService;

    /**
     * GET /transactions — Lịch sử giao dịch của user đang login
     */
    @GetMapping
    public ApiResponse<List<TransactionResponse>> getHistory(@AuthenticationPrincipal Jwt jwt) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        return ApiResponse.<List<TransactionResponse>>builder()
                .result(transactionService.getHistory(user.getUserId()))
                .build();
    }

    /**
     * GET /transactions/{id} — Chi tiết 1 giao dịch
     */
    @GetMapping("/{transactionId}")
    public ApiResponse<TransactionResponse> getById(@PathVariable Long transactionId) {
        return ApiResponse.<TransactionResponse>builder()
                .result(transactionService.getById(transactionId))
                .build();
    }

    /**
     * POST /transactions/withdraw — Yêu cầu rút tiền
     */
    @PostMapping("/withdraw")
    public ApiResponse<TransactionResponse> withdraw(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid WithdrawRequest request) {
        User user = userService.getUserEntityByEmail(jwt.getSubject());
        return ApiResponse.<TransactionResponse>builder()
                .result(transactionService.requestWithdrawal(user.getUserId(), request))
                .message("Withdrawal request created and pending approval")
                .build();
    }
}
