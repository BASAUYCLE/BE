package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.Transaction;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.entity.Wallet;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.TransactionStatus;
import com.swp391.bike_platform.enums.TransactionType;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.TransactionRepository;
import com.swp391.bike_platform.request.WithdrawRequest;
import com.swp391.bike_platform.response.TransactionResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final WalletService walletService;
    private final VnPayService vnPayService;
    private final UserService userService;

    private static final BigDecimal MIN_TOP_UP = new BigDecimal("10000");

    /**
     * Initiate a top-up: create PENDING transaction + return VNPay payment URL
     */
    @Transactional
    public String initiateTopUp(Long userId, BigDecimal amount, String ipAddress) {
        if (amount.compareTo(MIN_TOP_UP) < 0) {
            throw new AppException(ErrorCode.TOP_UP_MIN_AMOUNT);
        }

        Wallet wallet = walletService.getOrCreateWallet(userId);

        // Generate unique txn ref
        String txnRef = System.currentTimeMillis() + "_" + userId;

        Transaction transaction = Transaction.builder()
                .wallet(wallet)
                .user(wallet.getUser())
                .transactionType(TransactionType.TOP_UP.name())
                .amount(amount)
                .status(TransactionStatus.PENDING.name())
                .vnpTxnRef(txnRef)
                .description("+" + formatAmount(amount) + " VND - Nạp tiền ví")
                .build();
        if (transaction == null) {
            throw new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION);
        }
        transactionRepository.save(transaction);

        // Create VNPay URL
        return vnPayService.createPaymentUrl(
                amount.longValue(),
                txnRef,
                "Nap tien vi BaSauCycle",
                ipAddress);
    }

    /**
     * Handle VNPay return callback
     */
    @Transactional
    public TransactionResponse handleVnPayReturn(Map<String, String> params) {
        // Verify checksum
        if (!vnPayService.verifyReturnUrl(params)) {
            throw new AppException(ErrorCode.VNPAY_INVALID_CHECKSUM);
        }

        String txnRef = params.get("vnp_TxnRef");
        String responseCode = params.get("vnp_ResponseCode");
        String transactionNo = params.get("vnp_TransactionNo");
        String bankCode = params.get("vnp_BankCode");

        // Find transaction
        Transaction transaction = transactionRepository.findByVnpTxnRef(txnRef)
                .orElseThrow(() -> new AppException(ErrorCode.TRANSACTION_NOT_FOUND));

        // Update VNPay response fields
        transaction.setVnpResponseCode(responseCode);
        transaction.setVnpTransactionNo(transactionNo);
        transaction.setVnpBankCode(bankCode);

        if ("00".equals(responseCode)) {
            // Payment success
            transaction.setStatus(TransactionStatus.SUCCESS.name());
            walletService.addBalance(transaction.getWallet().getWalletId(), transaction.getAmount());
        } else {
            // Payment failed
            transaction.setStatus(TransactionStatus.FAILED.name());
        }

        transactionRepository.save(transaction);
        return toResponse(transaction);
    }

    /**
     * Get transaction history for a user
     */
    public List<TransactionResponse> getHistory(Long userId) {
        return transactionRepository.findByUser_UserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get ALL transactions for Admin with pagination
     */
    public Page<TransactionResponse> getAllTransactionsForAdmin(int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return transactionRepository.findAll(pageable).map(this::toResponse);
    }

    /**
     * Get single transaction by id
     */
    public TransactionResponse getById(Long transactionId) {
        if (transactionId == null) {
            throw new AppException(ErrorCode.TRANSACTION_NOT_FOUND);
        }
        Transaction t = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new AppException(ErrorCode.TRANSACTION_NOT_FOUND));
        return toResponse(t);
    }

    /**
     * Request a withdrawal (User)
     */
    @Transactional
    public TransactionResponse requestWithdrawal(Long userId, WithdrawRequest request) {
        Wallet wallet = walletService.getOrCreateWallet(userId);

        // Deduct balance first
        walletService.deductBalance(wallet.getWalletId(), request.getAmount());

        // Create PENDING withdrawal transaction
        Transaction transaction = Transaction.builder()
                .wallet(wallet)
                .user(wallet.getUser())
                .transactionType(TransactionType.WITHDRAW.name())
                .amount(request.getAmount())
                .status(TransactionStatus.PENDING.name())
                .bankName(request.getBankName())
                .bankAccountNumber(request.getBankAccountNumber())
                .bankAccountHolder(request.getBankAccountHolder())
                .description("-" + formatAmount(request.getAmount()) + " VND - Rút tiền về " + request.getBankName())
                .build();

        transactionRepository.save(transaction);
        return toResponse(transaction);
    }

    /**
     * Approve withdrawal (Admin)
     */
    @Transactional
    public TransactionResponse approveWithdrawal(Long transactionId) {
        Transaction t = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new AppException(ErrorCode.TRANSACTION_NOT_FOUND));

        if (!TransactionType.WITHDRAW.name().equals(t.getTransactionType()) ||
                !TransactionStatus.PENDING.name().equals(t.getStatus())) {
            throw new AppException(ErrorCode.WITHDRAW_INVALID_STATUS);
        }

        t.setStatus(TransactionStatus.SUCCESS.name());
        transactionRepository.save(t);
        return toResponse(t);
    }

    /**
     * Reject withdrawal (Admin)
     */
    @Transactional
    public TransactionResponse rejectWithdrawal(Long transactionId) {
        Transaction t = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new AppException(ErrorCode.TRANSACTION_NOT_FOUND));

        if (!TransactionType.WITHDRAW.name().equals(t.getTransactionType()) ||
                !TransactionStatus.PENDING.name().equals(t.getStatus())) {
            throw new AppException(ErrorCode.WITHDRAW_INVALID_STATUS);
        }

        t.setStatus(TransactionStatus.FAILED.name());

        // Refund balance to user
        walletService.addBalance(t.getWallet().getWalletId(), t.getAmount());

        transactionRepository.save(t);
        return toResponse(t);
    }

    /**
     * Create a transaction for order-related operations (deposit, purchase, refund,
     * posting fee)
     */
    @Transactional
    public void createOrderTransaction(Wallet wallet, User user, BicyclePost post,
            TransactionType type, BigDecimal amount,
            String description) {
        Transaction transaction = Transaction.builder()
                .wallet(wallet)
                .user(user)
                .post(post)
                .transactionType(type.name())
                .amount(amount)
                .status(TransactionStatus.SUCCESS.name())
                .description(description)
                .build();
        transactionRepository.save(transaction);
    }

    /**
     * Format amount with comma separators (e.g. 850,000)
     */
    public static String formatAmount(BigDecimal amount) {
        DecimalFormat df = new DecimalFormat("#,###");
        return df.format(amount);
    }

    private TransactionResponse toResponse(Transaction t) {
        return TransactionResponse.builder()
                .transactionId(t.getTransactionId())
                .transactionType(t.getTransactionType())
                .amount(t.getAmount())
                .status(t.getStatus())
                .description(t.getDescription())
                .vnpBankCode(t.getVnpBankCode())
                .vnpTxnRef(t.getVnpTxnRef())
                .vnpTransactionNo(t.getVnpTransactionNo())
                .postId(t.getPost() != null ? t.getPost().getPostId() : null)
                .userId(t.getUser() != null ? t.getUser().getUserId() : null)
                .userEmail(t.getUser() != null ? t.getUser().getEmail() : null)
                .userFullName(t.getUser() != null ? t.getUser().getFullName() : null)
                .bankName(t.getBankName())
                .bankAccountNumber(t.getBankAccountNumber())
                .bankAccountHolder(t.getBankAccountHolder())
                .createdAt(t.getCreatedAt())
                .build();
    }
}
