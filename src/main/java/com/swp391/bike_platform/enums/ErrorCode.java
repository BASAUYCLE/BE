package com.swp391.bike_platform.enums;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_KEY(1001, "Uncategorized error", HttpStatus.BAD_REQUEST),
    USER_EXISTED(1002, "User existed", HttpStatus.BAD_REQUEST),
    USERNAME_INVALID(1003, "Username must be at least 3 characters", HttpStatus.BAD_REQUEST),
    INVALID_PASSWORD(1004, "Password must be at least 8 characters", HttpStatus.BAD_REQUEST),
    USER_NOT_EXISTED(1005, "User not existed", HttpStatus.NOT_FOUND),
    UNAUTHENTICATED(1006, "Unauthenticated", HttpStatus.UNAUTHORIZED),
    UNAUTHORIZED(1007, "You do not have permission", HttpStatus.FORBIDDEN),
    INVALID_TOKEN(1008, "Token is invalid", HttpStatus.UNAUTHORIZED),
    TOKEN_EXPIRED(1009, "Token has expired", HttpStatus.UNAUTHORIZED),
    INVALID_EMAIL(1011, "Invalid email address", HttpStatus.BAD_REQUEST),
    IMAGE_UPLOAD_FAILED(1012, "Failed to upload image", HttpStatus.INTERNAL_SERVER_ERROR),
    TOKEN_CREATION_FAILED(1013, "Failed to create authentication token", HttpStatus.INTERNAL_SERVER_ERROR),
    BRAND_EXISTED(1014, "Brand already existed", HttpStatus.BAD_REQUEST),
    BRAND_NOT_EXISTED(1015, "Brand not existed", HttpStatus.NOT_FOUND),
    CATEGORY_EXISTED(1016, "Category already existed", HttpStatus.BAD_REQUEST),
    CATEGORY_NOT_EXISTED(1017, "Category not existed", HttpStatus.NOT_FOUND),
    POST_NOT_EXISTED(1018, "Bicycle post not existed", HttpStatus.NOT_FOUND),
    IMAGE_NOT_EXISTED(1019, "Bicycle image not existed", HttpStatus.NOT_FOUND),
    POST_UPDATE_NOT_ALLOWED(1020, "Cannot update post in current status", HttpStatus.BAD_REQUEST),
    INVALID_SIZE(1021, "Invalid bicycle size", HttpStatus.BAD_REQUEST),
    MISSING_REQUIRED_FIELD(1022, "Missing required field", HttpStatus.BAD_REQUEST),
    USER_HAS_NO_POSTS(1023, "User has no posts", HttpStatus.NOT_FOUND),
    NO_POSTS_FOR_BRAND(1024, "No posts found for this brand", HttpStatus.NOT_FOUND),
    NO_POSTS_FOR_CATEGORY(1025, "No posts found for this category", HttpStatus.NOT_FOUND),
    NO_POSTS_FOR_SIZE(1026, "No posts found for this size", HttpStatus.NOT_FOUND),
    NO_POSTS_FOR_STATUS(1027, "No posts found for this status", HttpStatus.NOT_FOUND),
    NO_POSTS_FOR_PRICE_RANGE(1028, "No posts found in this price range", HttpStatus.NOT_FOUND),
    EMAIL_SEND_FAILED(1029, "Failed to send email", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_VERIFY_ACTION(1030, "Invalid action. Use APPROVE or REJECT", HttpStatus.BAD_REQUEST),
    USER_ALREADY_VERIFIED(1031, "User is already verified", HttpStatus.BAD_REQUEST),
    USER_ALREADY_REJECTED(1032, "User is already rejected", HttpStatus.BAD_REQUEST),
    INVALID_POST_STATUS(1033, "Invalid post status for this action", HttpStatus.BAD_REQUEST),
    INVALID_RESET_TOKEN(1034, "Reset token is invalid", HttpStatus.BAD_REQUEST),
    RESET_TOKEN_EXPIRED(1035, "Reset token has expired", HttpStatus.BAD_REQUEST),
    WEAK_PASSWORD(1036,
            "Password must contain at least 8 characters, including uppercase, lowercase, number and special character",
            HttpStatus.BAD_REQUEST),
    WISHLIST_ALREADY_EXISTS(1037, "Post already in wishlist", HttpStatus.BAD_REQUEST),
    WISHLIST_NOT_FOUND(1038, "Post not in wishlist", HttpStatus.NOT_FOUND),
    CANNOT_WISHLIST_OWN_POST(1039, "Cannot add your own post to wishlist", HttpStatus.BAD_REQUEST),
    POST_NOT_AVAILABLE(1040, "Post is not available", HttpStatus.BAD_REQUEST),
    DRAFT_INCOMPLETE(1041, "Draft is incomplete, all fields are required before submitting", HttpStatus.BAD_REQUEST),
    POST_NOT_DRAFT(1042, "Post is not in DRAFTED status", HttpStatus.BAD_REQUEST),
    PROVINCE_NOT_FOUND(1043, "Province not found", HttpStatus.NOT_FOUND),
    COMMUNE_NOT_FOUND(1044, "Commune not found", HttpStatus.NOT_FOUND),
    ADDRESS_NOT_FOUND(1045, "Address not found", HttpStatus.NOT_FOUND),
    WALLET_NOT_FOUND(1046, "Wallet not found", HttpStatus.NOT_FOUND),
    INSUFFICIENT_BALANCE(1047, "Insufficient balance", HttpStatus.BAD_REQUEST),
    TRANSACTION_NOT_FOUND(1048, "Transaction not found", HttpStatus.NOT_FOUND),
    VNPAY_INVALID_CHECKSUM(1049, "VNPay checksum verification failed", HttpStatus.BAD_REQUEST),
    VNPAY_PAYMENT_FAILED(1050, "VNPay payment failed", HttpStatus.BAD_REQUEST),
    TOP_UP_MIN_AMOUNT(1051, "Minimum top-up amount is 10,000 VND", HttpStatus.BAD_REQUEST),
    CONFIG_NOT_FOUND(1052, "Configuration not found", HttpStatus.NOT_FOUND),
    INSUFFICIENT_BALANCE_FOR_POST(1053, "Insufficient balance to pay posting fee", HttpStatus.BAD_REQUEST),
    ORDER_NOT_FOUND(1054, "Order not found", HttpStatus.NOT_FOUND),
    CANNOT_ORDER_OWN_POST(1055, "Cannot order your own post", HttpStatus.BAD_REQUEST),
    POST_NOT_AVAILABLE_FOR_ORDER(1056, "Post is not available for ordering", HttpStatus.BAD_REQUEST),
    INVALID_ORDER_STATUS(1057, "Invalid order status for this action", HttpStatus.BAD_REQUEST),
    NOT_ORDER_BUYER(1058, "You are not the buyer of this order", HttpStatus.FORBIDDEN),
    NOT_ORDER_SELLER(1059, "You are not the seller of this order", HttpStatus.FORBIDDEN),
    ORDER_ALREADY_EXISTS(1060, "An active order already exists for this post", HttpStatus.BAD_REQUEST),
    FEEDBACK_ALREADY_EXISTS(1061, "Feedback already exists for this order", HttpStatus.BAD_REQUEST),
    FEEDBACK_NOT_FOUND(1062, "Feedback not found for this order", HttpStatus.NOT_FOUND),
    ORDER_NOT_COMPLETED(1063, "Order must be completed before leaving feedback", HttpStatus.BAD_REQUEST),
    INVALID_RATING(1064, "Rating must be between 1 and 5", HttpStatus.BAD_REQUEST),
    DISPUTE_NOT_FOUND(1065, "Dispute not found", HttpStatus.NOT_FOUND),
    DISPUTE_WINDOW_EXPIRED(1066, "Dispute window has expired", HttpStatus.BAD_REQUEST),
    INVALID_DISPUTE_STATUS(1067, "Invalid dispute status for this action", HttpStatus.BAD_REQUEST),
    NOT_DISPUTE_BUYER(1068, "You are not the buyer of this dispute", HttpStatus.FORBIDDEN),
    NOT_DISPUTE_SELLER(1069, "You are not the seller of this dispute", HttpStatus.FORBIDDEN),
    NOT_DISPUTE_INSPECTOR(1070, "You are not the assigned inspector of this dispute", HttpStatus.FORBIDDEN),
    ORDER_ALREADY_REVIEWED(1072, "Order has already been reviewed", HttpStatus.BAD_REQUEST),
    CANNOT_DISPUTE_COD_RECEIPT(1073, "Cannot dispute a COD order after successfully receiving it",
            HttpStatus.BAD_REQUEST),
            ;

    ErrorCode(int code, String message, HttpStatus statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }

    private final int code;
    private final String message;
    private final HttpStatus statusCode;
}
