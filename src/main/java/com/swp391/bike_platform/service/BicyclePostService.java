package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicycleImage;
import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.Brand;
import com.swp391.bike_platform.entity.Category;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.repository.BrandRepository;
import com.swp391.bike_platform.repository.CategoryRepository;
import com.swp391.bike_platform.repository.UserRepository;
import com.swp391.bike_platform.request.BicyclePostCreateRequest;
import com.swp391.bike_platform.request.BicyclePostUpdateRequest;
import com.swp391.bike_platform.response.BicycleImageResponse;
import com.swp391.bike_platform.response.BicyclePostResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BicyclePostService {

    private final BicyclePostRepository bicyclePostRepository;
    private final UserRepository userRepository;
    private final BrandRepository brandRepository;
    private final CategoryRepository categoryRepository;

    private static final List<String> VALID_SIZES = Arrays.asList(
            "XS (42 - 47) / 147 - 155 cm",
            "S (48 - 52) / 155 - 165 cm",
            "M (53 - 55) / 165 - 175 cm",
            "L (56 - 58) / 175 - 183 cm",
            "XL (59 - 60) / 183 - 191 cm",
            "XXL (61 - 63) / 191 - 198 cm");

    public BicyclePostResponse createPost(BicyclePostCreateRequest request) {
        log.info("Creating bicycle post: {}", request.getBicycleName());

        // Validate required fields
        validateRequiredFields(request);

        // Validate size
        if (!VALID_SIZES.contains(request.getSize())) {
            throw new AppException(ErrorCode.INVALID_SIZE);
        }

        // Get related entities
        User seller = userRepository.findById(request.getSellerId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        Brand brand = brandRepository.findById(request.getBrandId())
                .orElseThrow(() -> new AppException(ErrorCode.BRAND_NOT_EXISTED));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_EXISTED));

        // Build and save post
        BicyclePost post = BicyclePost.builder()
                .seller(seller)
                .brand(brand)
                .category(category)
                .bicycleName(request.getBicycleName().trim())
                .bicycleColor(request.getBicycleColor().trim())
                .price(request.getPrice())
                .bicycleDescription(request.getBicycleDescription().trim())
                .groupset(request.getGroupset().trim())
                .frameMaterial(request.getFrameMaterial().trim())
                .brakeType(request.getBrakeType().trim())
                .size(request.getSize())
                .modelYear(request.getModelYear())
                .postStatus("PENDING")
                .build();

        BicyclePost savedPost = bicyclePostRepository.save(post);
        log.info("Bicycle post created with ID: {}", savedPost.getPostId());

        return toPostResponse(savedPost);
    }

    public List<BicyclePostResponse> getAllPosts() {
        return bicyclePostRepository.findAll().stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public BicyclePostResponse getPostById(Long postId) {
        return toPostResponse(findPostById(postId));
    }

    public List<BicyclePostResponse> getPostsBySellerId(Long sellerId) {
        // Check if user exists
        if (!userRepository.existsById(sellerId)) {
            throw new AppException(ErrorCode.USER_NOT_EXISTED);
        }

        List<BicyclePost> posts = bicyclePostRepository.findBySeller_UserId(sellerId);

        // Check if user has any posts
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.USER_HAS_NO_POSTS);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsByBrandId(Long brandId) {
        // Check if brand exists
        if (!brandRepository.existsById(brandId)) {
            throw new AppException(ErrorCode.BRAND_NOT_EXISTED);
        }

        List<BicyclePost> posts = bicyclePostRepository.findByBrand_BrandId(brandId);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_BRAND);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsByCategoryId(Long categoryId) {
        // Check if category exists
        if (!categoryRepository.existsById(categoryId)) {
            throw new AppException(ErrorCode.CATEGORY_NOT_EXISTED);
        }

        List<BicyclePost> posts = bicyclePostRepository.findByCategory_CategoryId(categoryId);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_CATEGORY);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsBySize(String size) {
        if (!VALID_SIZES.contains(size)) {
            throw new AppException(ErrorCode.INVALID_SIZE);
        }

        List<BicyclePost> posts = bicyclePostRepository.findBySize(size);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_SIZE);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsByStatus(String status) {
        List<BicyclePost> posts = bicyclePostRepository.findByPostStatus(status.toUpperCase());
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_STATUS);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice) {
        List<BicyclePost> posts = bicyclePostRepository.findByPriceBetween(minPrice, maxPrice);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_PRICE_RANGE);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public BicyclePostResponse updatePost(Long postId, BicyclePostUpdateRequest request) {
        BicyclePost post = findPostById(postId);
        String currentStatus = post.getPostStatus();

        log.info("Updating post {} with status: {}", postId, currentStatus);

        // Check if update is allowed based on status
        if ("PENDING".equals(currentStatus)) {
            // Allow full update
            updateAllFields(post, request);
        } else if ("AVAILABLE".equals(currentStatus)) {
            // Only allow color, size, description update
            updateLimitedFields(post, request);
        } else {
            // DEPOSITED, SOLD, REJECTED - no update allowed
            throw new AppException(ErrorCode.POST_UPDATE_NOT_ALLOWED);
        }

        BicyclePost updatedPost = bicyclePostRepository.save(post);
        log.info("Post {} updated successfully", postId);

        return toPostResponse(updatedPost);
    }

    public void deletePost(Long postId) {
        if (!bicyclePostRepository.existsById(postId)) {
            throw new AppException(ErrorCode.POST_NOT_EXISTED);
        }
        bicyclePostRepository.deleteById(postId);
        log.info("Post {} deleted", postId);
    }

    // Helper methods
    private BicyclePost findPostById(Long postId) {
        return bicyclePostRepository.findById(postId)
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));
    }

    private void validateRequiredFields(BicyclePostCreateRequest request) {
        if (request.getSellerId() == null || request.getBrandId() == null ||
                request.getCategoryId() == null || request.getBicycleName() == null ||
                request.getBicycleColor() == null || request.getPrice() == null ||
                request.getBicycleDescription() == null || request.getGroupset() == null ||
                request.getFrameMaterial() == null || request.getBrakeType() == null ||
                request.getSize() == null || request.getModelYear() == null) {
            throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
        }
    }

    private void updateAllFields(BicyclePost post, BicyclePostUpdateRequest request) {
        if (request.getBrandId() != null) {
            Brand brand = brandRepository.findById(request.getBrandId())
                    .orElseThrow(() -> new AppException(ErrorCode.BRAND_NOT_EXISTED));
            post.setBrand(brand);
        }
        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_EXISTED));
            post.setCategory(category);
        }
        if (request.getBicycleName() != null) {
            post.setBicycleName(request.getBicycleName().trim());
        }
        if (request.getPrice() != null) {
            post.setPrice(request.getPrice());
        }
        if (request.getGroupset() != null) {
            post.setGroupset(request.getGroupset().trim());
        }
        if (request.getFrameMaterial() != null) {
            post.setFrameMaterial(request.getFrameMaterial().trim());
        }
        if (request.getBrakeType() != null) {
            post.setBrakeType(request.getBrakeType().trim());
        }
        if (request.getModelYear() != null) {
            post.setModelYear(request.getModelYear());
        }

        // Also update limited fields
        updateLimitedFields(post, request);
    }

    private void updateLimitedFields(BicyclePost post, BicyclePostUpdateRequest request) {
        if (request.getBicycleColor() != null) {
            post.setBicycleColor(request.getBicycleColor().trim());
        }
        if (request.getSize() != null) {
            if (!VALID_SIZES.contains(request.getSize())) {
                throw new AppException(ErrorCode.INVALID_SIZE);
            }
            post.setSize(request.getSize());
        }
        if (request.getBicycleDescription() != null) {
            post.setBicycleDescription(request.getBicycleDescription().trim());
        }
    }

    private BicyclePostResponse toPostResponse(BicyclePost post) {
        List<BicycleImageResponse> imageResponses = post.getImages().stream()
                .map(this::toImageResponse)
                .collect(Collectors.toList());

        return BicyclePostResponse.builder()
                .postId(post.getPostId())
                .sellerId(post.getSeller().getUserId())
                .sellerFullName(post.getSeller().getFullName())
                .sellerPhoneNumber(post.getSeller().getPhoneNumber())
                .brandId(post.getBrand().getBrandId())
                .brandName(post.getBrand().getBrandName())
                .categoryId(post.getCategory().getCategoryId())
                .categoryName(post.getCategory().getCategoryName())
                .bicycleName(post.getBicycleName())
                .bicycleColor(post.getBicycleColor())
                .price(post.getPrice())
                .bicycleDescription(post.getBicycleDescription())
                .groupset(post.getGroupset())
                .frameMaterial(post.getFrameMaterial())
                .brakeType(post.getBrakeType())
                .size(post.getSize())
                .modelYear(post.getModelYear())
                .postStatus(post.getPostStatus())
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .images(imageResponses)
                .build();
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
