package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Feedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FeedbackRepository extends JpaRepository<Feedback, Long> {

    Optional<Feedback> findByOrder_OrderId(Long orderId);

    List<Feedback> findBySeller_UserIdOrderByCreatedAtDesc(Long sellerId);

    List<Feedback> findByPost_PostIdOrderByCreatedAtDesc(Long postId);

    boolean existsByOrder_OrderId(Long orderId);

    @Query("SELECT AVG(f.rating) FROM Feedback f WHERE f.seller.userId = :sellerId")
    Double getAverageRatingBySellerId(@Param("sellerId") Long sellerId);

    @Query("SELECT COUNT(f) FROM Feedback f WHERE f.seller.userId = :sellerId")
    Long countBySellerId(@Param("sellerId") Long sellerId);
}
