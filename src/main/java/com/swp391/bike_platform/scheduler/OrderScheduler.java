package com.swp391.bike_platform.scheduler;

import com.swp391.bike_platform.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class OrderScheduler {

    private final OrderService orderService;

    /**
     * Auto-confirm SHIPPING orders after X days (configured in SystemConfig).
     * Runs every hour.
     */
    @Scheduled(fixedRate = 3600000)
    public void autoConfirmShippingOrders() {
        log.info("Running auto-confirm scheduler...");
        try {
            orderService.autoConfirmOrders();
        } catch (Exception e) {
            log.error("Auto-confirm scheduler error: {}", e.getMessage(), e);
        }
    }
}
