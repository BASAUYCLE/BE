package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.BicycleImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BicycleImageRepository extends JpaRepository<BicycleImage, Long> {

    List<BicycleImage> findByPost_PostId(Long postId);

    Optional<BicycleImage> findByPost_PostIdAndImageType(Long postId, String imageType);

    Optional<BicycleImage> findByPost_PostIdAndIsThumbnailTrue(Long postId);

    void deleteByPost_PostId(Long postId);
}
