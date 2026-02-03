package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicycleImage;
import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicycleImageRepository;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.request.BicycleImageCreateRequest;
import com.swp391.bike_platform.request.BicycleImageUpdateRequest;
import com.swp391.bike_platform.response.BicycleImageResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BicycleImageService {

    private final BicycleImageRepository bicycleImageRepository;
    private final BicyclePostRepository bicyclePostRepository;
    private final CloudinaryService cloudinaryService;

    private static final List<String> VALID_IMAGE_TYPES = Arrays.asList(
            "OVERALL_DRIVE_SIDE",
            "OVERALL_NON_DRIVE_SIDE",
            "COCKPIT_AREA",
            "DRIVETRAIN_CLOSEUP",
            "FRONT_BRAKE",
            "REAR_BRAKE",
            "DEFECT_POINT");

    public BicycleImageResponse createImage(BicycleImageCreateRequest request) {
        log.info("Creating bicycle image for post: {}", request.getPostId());

        // Validate post exists
        BicyclePost post = bicyclePostRepository.findById(request.getPostId())
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));

        // Validate image type
        if (!VALID_IMAGE_TYPES.contains(request.getImageType().toUpperCase())) {
            throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
        }

        // Upload image to Cloudinary
        String imageUrl;
        try {
            if (request.getImage() == null || request.getImage().isEmpty()) {
                throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
            }
            imageUrl = cloudinaryService.uploadImage(request.getImage());
            log.info("Image uploaded to Cloudinary: {}", imageUrl);
        } catch (IOException e) {
            log.error("Failed to upload image: {}", e.getMessage());
            throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
        }

        // Build and save image
        BicycleImage image = BicycleImage.builder()
                .post(post)
                .imageUrl(imageUrl)
                .imageType(request.getImageType().toUpperCase())
                .isThumbnail(request.getIsThumbnail() != null ? request.getIsThumbnail() : false)
                .build();

        BicycleImage savedImage = bicycleImageRepository.save(image);
        log.info("Bicycle image created with ID: {}", savedImage.getImageId());

        return toImageResponse(savedImage);
    }

    public List<BicycleImageResponse> getImagesByPostId(Long postId) {
        // Validate post exists
        if (!bicyclePostRepository.existsById(postId)) {
            throw new AppException(ErrorCode.POST_NOT_EXISTED);
        }

        return bicycleImageRepository.findByPost_PostId(postId).stream()
                .map(this::toImageResponse)
                .collect(Collectors.toList());
    }

    public BicycleImageResponse getImageById(Long imageId) {
        return toImageResponse(findImageById(imageId));
    }

    public BicycleImageResponse updateImage(Long imageId, BicycleImageUpdateRequest request) {
        BicycleImage image = findImageById(imageId);

        log.info("Updating image: {}", imageId);

        // Upload new image if provided
        if (request.getImage() != null && !request.getImage().isEmpty()) {
            try {
                String newImageUrl = cloudinaryService.uploadImage(request.getImage());
                image.setImageUrl(newImageUrl);
                log.info("New image uploaded: {}", newImageUrl);
            } catch (IOException e) {
                log.error("Failed to upload image: {}", e.getMessage());
                throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
            }
        }

        // Update image type if provided
        if (request.getImageType() != null) {
            if (!VALID_IMAGE_TYPES.contains(request.getImageType().toUpperCase())) {
                throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
            }
            image.setImageType(request.getImageType().toUpperCase());
        }

        // Update thumbnail flag if provided
        if (request.getIsThumbnail() != null) {
            image.setIsThumbnail(request.getIsThumbnail());
        }

        BicycleImage updatedImage = bicycleImageRepository.save(image);
        log.info("Image {} updated successfully", imageId);

        return toImageResponse(updatedImage);
    }

    @Transactional
    public void deleteImage(Long imageId) {
        if (!bicycleImageRepository.existsById(imageId)) {
            throw new AppException(ErrorCode.IMAGE_NOT_EXISTED);
        }
        bicycleImageRepository.deleteById(imageId);
        log.info("Image {} deleted", imageId);
    }

    @Transactional
    public void deleteImagesByPostId(Long postId) {
        bicycleImageRepository.deleteByPost_PostId(postId);
        log.info("All images for post {} deleted", postId);
    }

    // Helper methods
    private BicycleImage findImageById(Long imageId) {
        return bicycleImageRepository.findById(imageId)
                .orElseThrow(() -> new AppException(ErrorCode.IMAGE_NOT_EXISTED));
    }

    private BicycleImageResponse toImageResponse(BicycleImage image) {
        return BicycleImageResponse.builder()
                .imageId(image.getImageId())
                .postId(image.getPost().getPostId())
                .imageUrl(image.getImageUrl())
                .imageType(image.getImageType())
                .isThumbnail(image.getIsThumbnail())
                .createdAt(image.getCreatedAt())
                .updatedAt(image.getUpdatedAt())
                .build();
    }
}
