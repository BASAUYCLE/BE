package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicycleImage;
import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.entity.Wishlist;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.repository.UserRepository;
import com.swp391.bike_platform.repository.WishlistRepository;
import com.swp391.bike_platform.response.WishlistResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class WishlistService {

    private final WishlistRepository wishlistRepository;
    private final UserRepository userRepository;
    private final BicyclePostRepository bicyclePostRepository;

    public WishlistResponse addToWishlist(Long userId, Long postId) {
        // Check if already in wishlist
        if (wishlistRepository.existsByUser_UserIdAndPost_PostId(userId, postId)) {
            throw new AppException(ErrorCode.WISHLIST_ALREADY_EXISTS);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        BicyclePost post = bicyclePostRepository.findById(postId)
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));

        Wishlist wishlist = Wishlist.builder()
                .user(user)
                .post(post)
                .build();

        wishlist = wishlistRepository.save(wishlist);
        log.info("User {} added post {} to wishlist", userId, postId);

        return toWishlistResponse(wishlist);
    }

    @Transactional
    public void removeFromWishlist(Long userId, Long postId) {
        if (!wishlistRepository.existsByUser_UserIdAndPost_PostId(userId, postId)) {
            throw new AppException(ErrorCode.WISHLIST_NOT_FOUND);
        }

        wishlistRepository.deleteByUser_UserIdAndPost_PostId(userId, postId);
        log.info("User {} removed post {} from wishlist", userId, postId);
    }

    public List<WishlistResponse> getMyWishlist(Long userId) {
        return wishlistRepository.findByUser_UserId(userId)
                .stream()
                .map(this::toWishlistResponse)
                .collect(Collectors.toList());
    }

    public boolean isInWishlist(Long userId, Long postId) {
        return wishlistRepository.existsByUser_UserIdAndPost_PostId(userId, postId);
    }

    private WishlistResponse toWishlistResponse(Wishlist wishlist) {
        BicyclePost post = wishlist.getPost();

        // Find thumbnail image
        String thumbnailUrl = null;
        if (post.getImages() != null && !post.getImages().isEmpty()) {
            thumbnailUrl = post.getImages().stream()
                    .filter(img -> Boolean.TRUE.equals(img.getIsThumbnail()))
                    .findFirst()
                    .map(BicycleImage::getImageUrl)
                    .orElse(post.getImages().get(0).getImageUrl());
        }

        return WishlistResponse.builder()
                .wishlistId(wishlist.getWishlistId())
                .postId(post.getPostId())
                .bicycleName(post.getBicycleName())
                .brandName(post.getBrand() != null ? post.getBrand().getBrandName() : null)
                .price(post.getPrice())
                .postStatus(post.getPostStatus())
                .thumbnailUrl(thumbnailUrl)
                .createdAt(wishlist.getCreatedAt())
                .build();
    }
}
