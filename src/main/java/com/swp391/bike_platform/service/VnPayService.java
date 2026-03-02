package com.swp391.bike_platform.service;

import com.swp391.bike_platform.configuration.VnPayConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

@Service
@RequiredArgsConstructor
public class VnPayService {

    private final VnPayConfig vnPayConfig;

    /**
     * Create VNPay payment URL
     */
    public String createPaymentUrl(long amount, String txnRef, String orderInfo, String ipAddress) {
        Map<String, String> params = new TreeMap<>();

        params.put("vnp_Version", "2.1.0");
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", vnPayConfig.getTmnCode());
        params.put("vnp_Amount", String.valueOf(amount * 100)); // VNPay uses amount * 100
        params.put("vnp_CurrCode", "VND");
        params.put("vnp_TxnRef", txnRef);
        params.put("vnp_OrderInfo", orderInfo);
        params.put("vnp_OrderType", "other");
        params.put("vnp_Locale", "vn");
        params.put("vnp_ReturnUrl", vnPayConfig.getReturnUrl());
        params.put("vnp_IpAddr", ipAddress);

        // Create date
        Calendar cal = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
        params.put("vnp_CreateDate", formatter.format(cal.getTime()));

        // Expire date (15 minutes)
        cal.add(Calendar.MINUTE, 15);
        params.put("vnp_ExpireDate", formatter.format(cal.getTime()));

        // Build query string (params already sorted by TreeMap)
        StringBuilder query = new StringBuilder();
        StringBuilder hashData = new StringBuilder();

        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (hashData.length() > 0) {
                hashData.append("&");
                query.append("&");
            }
            hashData.append(entry.getKey()).append("=")
                    .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
            query.append(entry.getKey()).append("=")
                    .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
        }

        // Generate HMAC-SHA512 checksum
        String secureHash = hmacSHA512(vnPayConfig.getHashSecret(), hashData.toString());
        query.append("&vnp_SecureHash=").append(secureHash);

        return vnPayConfig.getPayUrl() + "?" + query;
    }

    /**
     * Verify checksum from VNPay return URL
     */
    public boolean verifyReturnUrl(Map<String, String> params) {
        String vnpSecureHash = params.get("vnp_SecureHash");
        if (vnpSecureHash == null)
            return false;

        // Remove hash params
        Map<String, String> cleanParams = new TreeMap<>(params);
        cleanParams.remove("vnp_SecureHash");
        cleanParams.remove("vnp_SecureHashType");

        // Build hash data
        StringBuilder hashData = new StringBuilder();
        for (Map.Entry<String, String> entry : cleanParams.entrySet()) {
            if (hashData.length() > 0) {
                hashData.append("&");
            }
            hashData.append(entry.getKey()).append("=")
                    .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
        }

        String calculatedHash = hmacSHA512(vnPayConfig.getHashSecret(), hashData.toString());
        return calculatedHash.equalsIgnoreCase(vnpSecureHash);
    }

    /**
     * HMAC-SHA512 hashing
     */
    private String hmacSHA512(String key, String data) {
        try {
            Mac hmac512 = Mac.getInstance("HmacSHA512");
            SecretKeySpec secretKey = new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA512");
            hmac512.init(secretKey);
            byte[] result = hmac512.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(2 * result.length);
            for (byte b : result) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();
        } catch (Exception e) {
            return "";
        }
    }
}
