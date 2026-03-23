package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.TransactionResponse;
import com.swp391.bike_platform.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/transactions")
@RequiredArgsConstructor
public class AdminTransactionController {

    private final TransactionService transactionService;

    /**
     * GET /admin/transactions
     * Admin: Lấy toàn bộ giao dịch với pagination
     * query params:
     * - page: int (default 0)
     * - size: int (default 20)
     */
    @GetMapping
    public ApiResponse<Page<TransactionResponse>> getAllTransactions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        return ApiResponse.<Page<TransactionResponse>>builder()
                .result(transactionService.getAllTransactionsForAdmin(page, size))
                .build();
    }
}
