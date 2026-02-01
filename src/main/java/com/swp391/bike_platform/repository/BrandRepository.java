package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Brand;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BrandRepository extends JpaRepository<Brand, Long> {
    Optional<Brand> findByBrandName(String brandName);
    
    boolean existsByBrandName(String brandName);
}
