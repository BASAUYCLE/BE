package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Dispute;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface DisputeRepository extends JpaRepository<Dispute, Long> {
        List<Dispute> findByBuyer_UserIdOrderByCreatedAtDesc(Long buyerId);

        List<Dispute> findByOrder_Post_Seller_UserIdOrderByCreatedAtDesc(Long sellerId);

        List<Dispute> findByInspector_UserIdOrderByCreatedAtDesc(Long inspectorId);

        // Gộp cả Buyer lẫn Seller trong 1 query
        @Query("SELECT d FROM Dispute d WHERE d.buyer.userId = :userId OR d.order.post.seller.userId = :userId ORDER BY d.createdAt DESC")
        List<Dispute> findByBuyerOrSeller(@Param("userId") Long userId);

        // Dùng cho autoCompleteDeliveredOrders — check xem Order có dispute chưa
        boolean existsByOrder_OrderIdAndStatusNot(Long orderId, String excludedStatus);

        @Query("SELECT d FROM Dispute d WHERE d.status = :status AND d.updatedAt < :deadline")
        List<Dispute> findByStatusAndUpdatedAtBefore(@Param("status") String status,
                        @Param("deadline") LocalDateTime deadline);

        @Query("SELECT d FROM Dispute d WHERE d.status = :status AND d.returnShippedAt < :deadline")
        List<Dispute> findByStatusAndReturnShippedAtBefore(@Param("status") String status,
                        @Param("deadline") LocalDateTime deadline);

        // Admin: get all disputes
        List<Dispute> findAllByOrderByCreatedAtDesc();

        // Inspector: get available disputes (OPEN and no inspector) or disputes
        // assigned to this inspector
        @Query("SELECT d FROM Dispute d WHERE d.inspector IS NULL OR d.inspector.userId = :inspectorId ORDER BY d.createdAt DESC")
        List<Dispute> findAvailableOrAssignedToInspector(@Param("inspectorId") Long inspectorId);

        // Inspector: get resolved/rejected disputes assigned to this inspector
        @Query("SELECT d FROM Dispute d WHERE d.inspector.userId = :inspectorId " +
                        "AND d.status IN ('RESOLVED', 'REJECTED') " +
                        "ORDER BY d.resolvedAt DESC")
        List<Dispute> findResolvedByInspectorAssigned(@Param("inspectorId") Long inspectorId);
}
