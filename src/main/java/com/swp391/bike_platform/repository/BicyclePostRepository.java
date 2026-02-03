package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.BicyclePost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface BicyclePostRepository extends JpaRepository<BicyclePost, Long> {

    List<BicyclePost> findBySeller_UserId(Long sellerId);

    List<BicyclePost> findByBrand_BrandId(Long brandId);

    List<BicyclePost> findByCategory_CategoryId(Long categoryId);

    List<BicyclePost> findBySize(String size);

    List<BicyclePost> findByPostStatus(String postStatus);

    List<BicyclePost> findByPriceBetween(BigDecimal minPrice, BigDecimal maxPrice);

    List<BicyclePost> findByBrand_BrandIdAndCategory_CategoryId(Long brandId, Long categoryId);

    List<BicyclePost> findByBrand_BrandIdAndSize(Long brandId, String size);

    List<BicyclePost> findByCategory_CategoryIdAndSize(Long categoryId, String size);
}
