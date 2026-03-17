package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicycleImage;
import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.entity.Wallet;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.PostStatus;
import com.swp391.bike_platform.enums.TransactionType;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.response.BicycleImageResponse;
import com.swp391.bike_platform.response.BicyclePostResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminPostService {

    private final BicyclePostRepository bicyclePostRepository;
    private final WalletService walletService;
    private final TransactionService transactionService;
    private final SystemConfigService systemConfigService;

    /**
     * Lấy danh sách bài đăng đang chờ Admin duyệt (status = PENDING)
     */
    public List<BicyclePostResponse> getPendingPosts() {
        List<BicyclePost> posts = bicyclePostRepository.findByPostStatus(PostStatus.PENDING.name());
        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy TẤT CẢ bài đăng (Admin only)
     */
    public List<BicyclePostResponse> getAllPosts() {
        return bicyclePostRepository.findAll().stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lấy bài đăng theo status cụ thể (Admin only)
     */
    public List<BicyclePostResponse> getPostsByStatus(String status) {
        List<BicyclePost> posts = bicyclePostRepository.findByPostStatus(status.toUpperCase());
        return posts.stream()
                .map(this::toPostResponse)
                .collect(Collectors.toList());
    }

    /**
     * Admin duyệt bài đăng: PENDING -> ADMIN_APPROVED
     */
    public BicyclePostResponse approvePost(Long postId) {
        BicyclePost post = findPostById(postId);

        if (!PostStatus.PENDING.name().equals(post.getPostStatus())) {
            throw new AppException(ErrorCode.INVALID_POST_STATUS);
        }

        post.setPostStatus(PostStatus.ADMIN_APPROVED.name());
        BicyclePost savedPost = bicyclePostRepository.save(post);
        log.info("Post {} approved by Admin, status changed to ADMIN_APPROVED", postId);

        return toPostResponse(savedPost);
    }

    /**
     * Admin từ chối bài đăng: PENDING -> REJECTED
     */
    public BicyclePostResponse rejectPost(Long postId) {
        BicyclePost post = findPostById(postId);

        if (!PostStatus.PENDING.name().equals(post.getPostStatus())) {
            throw new AppException(ErrorCode.INVALID_POST_STATUS);
        }

        post.setPostStatus(PostStatus.REJECTED.name());
        BicyclePost savedPost = bicyclePostRepository.save(post);

        // Hoàn phí đăng bài cho người bán
        refundPostingFee(post.getSeller(), post);

        log.info("Post {} rejected by Admin, posting fee refunded to seller {}", postId, post.getSeller().getUserId());

        return toPostResponse(savedPost);
    }

    /**
     * Hoàn phí đăng bài vào ví người bán và tạo transaction REFUND
     */
    private void refundPostingFee(User seller, BicyclePost post) {
        BigDecimal postingFee = systemConfigService.getPostingFee();
        Wallet sellerWallet = walletService.getOrCreateWallet(seller.getUserId());

        walletService.addBalance(sellerWallet.getWalletId(), postingFee);

        transactionService.createOrderTransaction(
                sellerWallet, seller, post,
                TransactionType.REFUND, postingFee,
                "+" + TransactionService.formatAmount(postingFee) + " VND - Hoàn phí đăng bài (bài bị từ chối)");
    }

    /**
     * Admin ẩn bài đăng (soft delete): Any status -> HIDDEN
     */
    public BicyclePostResponse hidePost(Long postId) {
        BicyclePost post = findPostById(postId);

        post.setPostStatus(PostStatus.HIDDEN.name());
        BicyclePost savedPost = bicyclePostRepository.save(post);
        log.info("Post {} hidden by Admin (soft delete)", postId);

        return toPostResponse(savedPost);
    }

    private BicyclePost findPostById(Long postId) {
        return bicyclePostRepository.findById(postId)
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));
    }

    private BicyclePostResponse toPostResponse(BicyclePost post) {
        List<BicycleImageResponse> imageResponses = post.getImages().stream()
                .filter(image -> Boolean.TRUE.equals(image.getIsThumbnail()))
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
