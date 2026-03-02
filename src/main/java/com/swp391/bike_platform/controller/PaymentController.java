package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.response.TransactionResponse;
import com.swp391.bike_platform.service.TransactionService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/payment")
@RequiredArgsConstructor
public class PaymentController {

    private final TransactionService transactionService;

    @Value("${app.frontend-url}")
    private String frontendUrl;

    /**
     * GET /payment/vnpay/callback — VNPay redirect browser về đây
     * Public endpoint (permitAll), vì browser redirect
     */
    @GetMapping("/vnpay/callback")
    public void vnPayCallback(@RequestParam Map<String, String> params,
            HttpServletResponse response) throws IOException {
        TransactionResponse result = transactionService.handleVnPayReturn(params);

        // Redirect to frontend with result
        String status = "SUCCESS".equals(result.getStatus()) ? "success" : "failed";
        String redirectUrl = frontendUrl + "/payment/result?status=" + status
                + "&amount=" + result.getAmount()
                + "&transactionId=" + result.getTransactionId();

        response.sendRedirect(redirectUrl);
    }
}
