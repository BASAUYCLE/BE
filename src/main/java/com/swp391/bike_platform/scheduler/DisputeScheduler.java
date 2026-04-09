package com.swp391.bike_platform.scheduler;

import com.swp391.bike_platform.service.DisputeService;
import com.swp391.bike_platform.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DisputeScheduler {
    private final OrderService orderService;
    private final DisputeService disputeService;

    // Run every 1 Hour
    @Scheduled(cron = "0 0 * * * *")
    public void processAutoTriggers() {
        log.info("CronJob Dispute Auto Checker START");

        try {
            // 1. SHIPPED -> DELIVERED after config days
            orderService.autoConfirmOrders();
        } catch (Exception e) {
            log.error("Failed to auto confirm orders: {}", e.getMessage(), e);
        }

        try {
            // 2. DELIVERED -> COMPLETED after dispute window without active dispute
            orderService.autoCompleteDeliveredOrders();
        } catch (Exception e) {
            log.error("Failed to auto complete delivered orders: {}", e.getMessage(), e);
        }

        try {
            // 2.5 DEPOSITED/PAID -> CANCELLED after auto cancel days
            orderService.autoCancelUnconfirmedOrders();
        } catch (Exception e) {
            log.error("Failed to auto cancel unshipped orders: {}", e.getMessage(), e);
        }

        try {
            // 3. APPROVED -> REJECTED (Buyer didn't ship return item)
            disputeService.autoCloseUnshippedDisputes();
        } catch (Exception e) {
            log.error("Failed to auto close unshipped disputes: {}", e.getMessage(), e);
        }

        try {
            // 4. RETURN_SHIPPED -> RESOLVED (Seller ignores return)
            disputeService.autoRefundShippedDisputes();
        } catch (Exception e) {
            log.error("Failed to auto refund shipped disputes: {}", e.getMessage(), e);
        }

        log.info("CronJob Dispute Auto Checker END");
    }
}
