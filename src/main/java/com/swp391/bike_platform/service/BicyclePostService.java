package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.*;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.PostStatus;
import com.swp391.bike_platform.enums.TransactionType;
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
    private final WalletService walletService;
    private final TransactionService transactionService;
    private final SystemConfigService systemConfigService;

    // Statuses visible to public users (Mercari style)
    private static final List<String> PUBLIC_STATUSES = Arrays.asList(
            PostStatus.AVAILABLE.name(),
            PostStatus.PROCESSING.name(),
            PostStatus.DEPOSITED.name(),
            PostStatus.SOLD.name());

    public BicyclePostResponse createPost(BicyclePostCreateRequest request) {
        log.info("Creating bicycle post: {}", request.getBicycleName());

        // Validate required fields
        validateRequiredFields(request);

        // Get related entities
        User seller = userRepository.findById(request.getSellerId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        // Deduct posting fee
        deductPostingFee(seller);

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
                .postStatus(PostStatus.PENDING.name())
                .build();

        BicyclePost savedPost = bicyclePostRepository.save(post);
        log.info("Bicycle post created with ID: {}", savedPost.getPostId());

        return toPostResponse(savedPost);
    }

    public List<BicyclePostResponse> getAllPosts() {
        return bicyclePostRepository.findByPostStatusIn(PUBLIC_STATUSES).stream()
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

        // Only return public statuses (AVAILABLE, DEPOSITED, SOLD)
        List<BicyclePost> posts = bicyclePostRepository.findBySeller_UserIdAndPostStatusIn(sellerId, PUBLIC_STATUSES);

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

        List<BicyclePost> posts = bicyclePostRepository.findByBrand_BrandIdAndPostStatusIn(brandId, PUBLIC_STATUSES);
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

        List<BicyclePost> posts = bicyclePostRepository.findByCategory_CategoryIdAndPostStatusIn(categoryId,
                PUBLIC_STATUSES);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_CATEGORY);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsBySize(String size) {
        List<BicyclePost> posts = bicyclePostRepository.findBySizeAndPostStatusIn(size, PUBLIC_STATUSES);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_SIZE);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    // REMOVED: getPostsByStatus - Security risk! Use Admin endpoint instead.

    public List<BicyclePostResponse> getPostsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice) {
        List<BicyclePost> posts = bicyclePostRepository.findByPriceBetweenAndPostStatusIn(minPrice, maxPrice,
                PUBLIC_STATUSES);
        if (posts.isEmpty()) {
            throw new AppException(ErrorCode.NO_POSTS_FOR_PRICE_RANGE);
        }

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public List<BicyclePostResponse> getPostsByKeyword(String keyword) {
        List<BicyclePost> posts = bicyclePostRepository.findByBicycleNameContainingIgnoreCaseAndPostStatusIn(keyword,
                PUBLIC_STATUSES);

        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public BicyclePostResponse updatePost(Long postId, Long userId, BicyclePostUpdateRequest request) {
        BicyclePost post = findPostById(postId);

        // Check ownership
        if (!post.getSeller().getUserId().equals(userId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        String currentStatus = post.getPostStatus();

        log.info("Updating post {} with status: {}", postId, currentStatus);

        // Check if update is allowed based on status
        if (PostStatus.PENDING.name().equals(currentStatus) || "DRAFTED".equals(currentStatus)) {
            // Allow full update for PENDING and DRAFTED
            updateAllFields(post, request);
        } else if (PostStatus.AVAILABLE.name().equals(currentStatus)) {
            // Only allow color, size, description update
            updateLimitedFields(post, request);
        } else {
            // DEPOSITED, SOLD, REJECTED, ADMIN_APPROVED - no update allowed
            throw new AppException(ErrorCode.POST_UPDATE_NOT_ALLOWED);
        }

        BicyclePost updatedPost = bicyclePostRepository.save(post);
        log.info("Post {} updated successfully", postId);

        return toPostResponse(updatedPost);
    }

    // ============ METHODS FOR CURRENT USER ============

    public List<BicyclePostResponse> getMyPosts(Long userId) {
        // Check if user exists
        if (!userRepository.existsById(userId)) {
            throw new AppException(ErrorCode.USER_NOT_EXISTED);
        }

        List<BicyclePost> posts = bicyclePostRepository.findBySeller_UserId(userId);
        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public BicyclePostResponse createDraftPost(Long userId, BicyclePostCreateRequest request) {
        log.info("Creating draft post for user: {}", userId);

        // Validate only required fields for draft (DB NOT NULL constraints)
        validateDraftFields(request);

        // Get related entities
        User seller = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        Brand brand = brandRepository.findById(request.getBrandId())
                .orElseThrow(() -> new AppException(ErrorCode.BRAND_NOT_EXISTED));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_EXISTED));

        // Build and save post with DRAFTED status (optional fields may be null)
        BicyclePost post = BicyclePost.builder()
                .seller(seller)
                .brand(brand)
                .category(category)
                .bicycleName(request.getBicycleName().trim())
                .bicycleColor(request.getBicycleColor() != null ? request.getBicycleColor().trim() : null)
                .price(request.getPrice())
                .bicycleDescription(
                        request.getBicycleDescription() != null ? request.getBicycleDescription().trim() : null)
                .groupset(request.getGroupset() != null ? request.getGroupset().trim() : null)
                .frameMaterial(request.getFrameMaterial() != null ? request.getFrameMaterial().trim() : null)
                .brakeType(request.getBrakeType() != null ? request.getBrakeType().trim() : null)
                .size(request.getSize())
                .modelYear(request.getModelYear())
                .postStatus("DRAFTED")
                .build();

        BicyclePost savedPost = bicyclePostRepository.save(post);
        log.info("Draft post created with ID: {}", savedPost.getPostId());

        return toPostResponse(savedPost);
    }

    public List<BicyclePostResponse> getMyDrafts(Long userId) {
        // Check if user exists
        if (!userRepository.existsById(userId)) {
            throw new AppException(ErrorCode.USER_NOT_EXISTED);
        }

        List<BicyclePost> drafts = bicyclePostRepository.findBySeller_UserIdAndPostStatus(userId, "DRAFTED");
        return drafts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    public BicyclePostResponse submitDraft(Long postId, Long userId) {
        log.info("Submitting draft post {} by user {}", postId, userId);

        BicyclePost post = findPostById(postId);

        // Check ownership
        if (!post.getSeller().getUserId().equals(userId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        // Check status is DRAFTED
        if (!PostStatus.DRAFTED.name().equals(post.getPostStatus())) {
            throw new AppException(ErrorCode.POST_NOT_DRAFT);
        }

        // Validate all fields are complete before submitting
        validateDraftComplete(post);

        // Deduct posting fee
        deductPostingFee(post.getSeller());

        // Transition to PENDING
        post.setPostStatus(PostStatus.PENDING.name());
        BicyclePost savedPost = bicyclePostRepository.save(post);
        log.info("Draft post {} submitted, now PENDING", postId);

        return toPostResponse(savedPost);
    }

    // ============ DRAFT VALIDATION HELPERS ============

    private void validateDraftFields(BicyclePostCreateRequest request) {
        if (request.getBrandId() == null || request.getCategoryId() == null ||
                request.getBicycleName() == null || request.getPrice() == null) {
            throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
        }
    }

    private void validateDraftComplete(BicyclePost post) {
        if (post.getBrand() == null || post.getCategory() == null ||
                post.getBicycleName() == null || post.getBicycleColor() == null ||
                post.getPrice() == null || post.getBicycleDescription() == null ||
                post.getGroupset() == null || post.getFrameMaterial() == null ||
                post.getBrakeType() == null || post.getSize() == null ||
                post.getModelYear() == null) {
            throw new AppException(ErrorCode.DRAFT_INCOMPLETE);
        }
    }

    public void deletePost(Long postId, Long userId) {
        BicyclePost post = findPostById(postId);

        // Check ownership
        if (!post.getSeller().getUserId().equals(userId)) {
            throw new AppException(ErrorCode.UNAUTHORIZED);
        }

        bicyclePostRepository.deleteById(postId);
        log.info("Post {} deleted by user {}", postId, userId);
    }

    // Helper methods

    /**
     * Deduct posting fee from seller wallet and create POSTING_FEE transaction
     */
    private void deductPostingFee(User seller) {
        BigDecimal postingFee = systemConfigService.getPostingFee();
        Wallet sellerWallet = walletService.getOrCreateWallet(seller.getUserId());

        if (sellerWallet.getBalance().compareTo(postingFee) < 0) {
            throw new AppException(ErrorCode.INSUFFICIENT_BALANCE_FOR_POST);
        }

        walletService.deductBalance(sellerWallet.getWalletId(), postingFee);

        transactionService.createOrderTransaction(
                sellerWallet, seller, null,
                TransactionType.POSTING_FEE, postingFee,
                "-" + TransactionService.formatAmount(postingFee) + " VND - Phí đăng bài");

        log.info("Posting fee {} deducted from user {}", postingFee, seller.getUserId());
    }

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
                .sellerAvatarUrl(post.getSeller().getAvatarUrl())
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
