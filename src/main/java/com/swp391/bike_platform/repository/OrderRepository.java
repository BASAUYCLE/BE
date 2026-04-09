package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    // Buyer's orders
    List<Order> findByBuyer_UserIdOrderByCreatedAtDesc(Long buyerId);

    // Seller's sales (through post.seller)
    @Query("SELECT o FROM Order o WHERE o.post.seller.userId = :sellerId ORDER BY o.createdAt DESC")
    List<Order> findBySellerId(@Param("sellerId") Long sellerId);

    // Check if post has an active order (not CANCELLED or COMPLETED)
    @Query("SELECT o FROM Order o WHERE o.post.postId = :postId AND o.orderStatus IN :statuses")
    List<Order> findByPostIdAndStatuses(@Param("postId") Long postId, @Param("statuses") List<String> statuses);

    // Auto-confirm: find SHIPPING orders where shippedAt is before the cutoff
    @Query("SELECT o FROM Order o WHERE o.orderStatus = :status AND o.shippedAt <= :cutoff")
    List<Order> findByStatusAndShippedAtBefore(@Param("status") String status, @Param("cutoff") LocalDateTime cutoff);

    // Auto-complete: find DELIVERED orders where deliveredAt is before the cutoff
    @Query("SELECT o FROM Order o WHERE o.orderStatus = :status AND o.deliveredAt <= :cutoff")
    List<Order> findByStatusAndDeliveredAtBefore(@Param("status") String status, @Param("cutoff") LocalDateTime cutoff);

    // Auto-cancel: find DEPOSITED/PAID orders where shippedAt IS NULL and createdAt
    // is before the cutoff
    @Query("SELECT o FROM Order o WHERE o.orderStatus IN :statuses AND o.shippedAt IS NULL AND o.createdAt <= :cutoff")
    List<Order> findUnshippedOrdersBefore(@Param("statuses") List<String> statuses,
            @Param("cutoff") LocalDateTime cutoff);

    boolean existsByAddress_AddressId(Long addressId);
}
