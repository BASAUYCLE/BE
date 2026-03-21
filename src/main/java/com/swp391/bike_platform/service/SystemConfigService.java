package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.SystemConfig;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.SystemConfigRepository;
import com.swp391.bike_platform.response.SystemConfigResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SystemConfigService {

    private final SystemConfigRepository systemConfigRepository;

    /**
     * Get deposit rate as percentage (e.g. 10 means 10%)
     */
    public BigDecimal getDepositRate() {
        return getConfigAsBigDecimal("DEPOSIT_RATE");
    }

    /**
     * Get posting fee amount in VND
     */
    public BigDecimal getPostingFee() {
        return getConfigAsBigDecimal("POSTING_FEE");
    }

    /**
     * Get auto-confirm days
     */
    public int getAutoConfirmDays() {
        return Integer.parseInt(getConfigValue("AUTO_CONFIRM_DAYS"));
    }

    /**
     * Get dispute window days (default 3)
     */
    public int getDisputeWindowDays() {
        try {
            return Integer.parseInt(getConfigValue("DISPUTE_WINDOW_DAYS"));
        } catch (AppException e) {
            return 3;
        }
    }

    /**
     * Get days for auto closing unshipped dispute (default 5)
     */
    public int getAutoCloseUnshippedDisputeDays() {
        try {
            return Integer.parseInt(getConfigValue("AUTO_CLOSE_UNSHIPPED_DISPUTE_DAYS"));
        } catch (AppException e) {
            return 5;
        }
    }

    /**
     * Get days for auto refunding shipped dispute (default 7)
     */
    public int getAutoRefundShippedDisputeDays() {
        try {
            return Integer.parseInt(getConfigValue("AUTO_REFUND_SHIPPED_DISPUTE_DAYS"));
        } catch (AppException e) {
            return 7;
        }
    }

    /**
     * Get config value by key
     */
    public String getConfigValue(String key) {
        return systemConfigRepository.findById(key)
                .map(SystemConfig::getConfigValue)
                .orElseThrow(() -> new AppException(ErrorCode.CONFIG_NOT_FOUND));
    }

    /**
     * Update config value
     */
    @Transactional
    public SystemConfigResponse updateConfig(String key, String value) {
        SystemConfig config = systemConfigRepository.findById(key)
                .orElseThrow(() -> new AppException(ErrorCode.CONFIG_NOT_FOUND));
        config.setConfigValue(value);
        SystemConfig saved = systemConfigRepository.save(config);
        return toResponse(saved);
    }

    /**
     * Get all configurations
     */
    public List<SystemConfigResponse> getAllConfigs() {
        return systemConfigRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get single config response
     */
    public SystemConfigResponse getConfig(String key) {
        SystemConfig config = systemConfigRepository.findById(key)
                .orElseThrow(() -> new AppException(ErrorCode.CONFIG_NOT_FOUND));
        return toResponse(config);
    }

    private BigDecimal getConfigAsBigDecimal(String key) {
        return new BigDecimal(getConfigValue(key));
    }

    private SystemConfigResponse toResponse(SystemConfig config) {
        return SystemConfigResponse.builder()
                .key(config.getConfigKey())
                .value(config.getConfigValue())
                .description(config.getDescription())
                .build();
    }
}
