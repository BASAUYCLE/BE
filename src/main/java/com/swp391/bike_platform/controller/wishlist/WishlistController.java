package com.swp391.bike_platform.controller.wishlist;

import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.WishlistResponse;
import com.swp391.bike_platform.service.WishlistService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/wishlist")
@RequiredArgsConstructor
public class WishlistController {

    private final WishlistService wishlistService;

    /**
     * POST /wishlist/{postId}
     * Thêm bài đăng vào danh sách yêu thích
     */
    @PostMapping("/{postId}")
    public ApiResponse<WishlistResponse> addToWishlist(
            @PathVariable Long postId,
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        return ApiResponse.<WishlistResponse>builder()
                .result(wishlistService.addToWishlist(userId, postId))
                .message("Added to wishlist")
                .build();
    }

    /**
     * DELETE /wishlist/{postId}
     * Xóa bài đăng khỏi danh sách yêu thích
     */
    @DeleteMapping("/{postId}")
    public ApiResponse<Void> removeFromWishlist(
            @PathVariable Long postId,
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        wishlistService.removeFromWishlist(userId, postId);
        return ApiResponse.<Void>builder()
                .message("Removed from wishlist")
                .build();
    }

    /**
     * GET /wishlist
     * Lấy danh sách yêu thích của user đang đăng nhập
     */
    @GetMapping
    public ApiResponse<List<WishlistResponse>> getMyWishlist(
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        return ApiResponse.<List<WishlistResponse>>builder()
                .result(wishlistService.getMyWishlist(userId))
                .build();
    }

    /**
     * GET /wishlist/check/{postId}
     * Kiểm tra bài đăng có trong wishlist không
     */
    @GetMapping("/check/{postId}")
    public ApiResponse<Map<String, Boolean>> checkWishlist(
            @PathVariable Long postId,
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        boolean inWishlist = wishlistService.isInWishlist(userId, postId);
        return ApiResponse.<Map<String, Boolean>>builder()
                .result(Map.of("inWishlist", inWishlist))
                .build();
    }
}
