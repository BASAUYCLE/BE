package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.BicyclePost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface BicyclePostRepository extends JpaRepository<BicyclePost, Long> {

    List<BicyclePost> findBySeller_UserId(Long sellerId);

    List<BicyclePost> findBySeller_UserIdAndPostStatus(Long sellerId, String postStatus);

    List<BicyclePost> findByBrand_BrandId(Long brandId);

    List<BicyclePost> findByCategory_CategoryId(Long categoryId);

    List<BicyclePost> findBySize(String size);

    List<BicyclePost> findByPostStatus(String postStatus);

    List<BicyclePost> findByPostStatusIn(java.util.Collection<String> postStatuses);

    List<BicyclePost> findBySeller_UserIdAndPostStatusIn(Long sellerId, java.util.Collection<String> postStatuses);

    List<BicyclePost> findByPriceBetween(BigDecimal minPrice, BigDecimal maxPrice);

    List<BicyclePost> findByBrand_BrandIdAndCategory_CategoryId(Long brandId, Long categoryId);

    List<BicyclePost> findByBrand_BrandIdAndSize(Long brandId, String size);

    List<BicyclePost> findByCategory_CategoryIdAndSize(Long categoryId, String size);

    // ==========================================
    // NEW METHODS FOR PUBLIC FILTERING (Fixing visibility)
    // ==========================================

    List<BicyclePost> findByBrand_BrandIdAndPostStatus(Long brandId, String postStatus);

    List<BicyclePost> findByCategory_CategoryIdAndPostStatus(Long categoryId, String postStatus);

    List<BicyclePost> findBySizeAndPostStatus(String size, String postStatus);

    List<BicyclePost> findByPriceBetweenAndPostStatus(BigDecimal minPrice, BigDecimal maxPrice, String postStatus);

    // IN clause methods for multiple statuses
    List<BicyclePost> findByBrand_BrandIdAndPostStatusIn(Long brandId, java.util.Collection<String> postStatuses);

    List<BicyclePost> findByCategory_CategoryIdAndPostStatusIn(Long categoryId,
            java.util.Collection<String> postStatuses);

    List<BicyclePost> findBySizeAndPostStatusIn(String size, java.util.Collection<String> postStatuses);

    List<BicyclePost> findByPriceBetweenAndPostStatusIn(BigDecimal minPrice, BigDecimal maxPrice,
            java.util.Collection<String> postStatuses);
}
