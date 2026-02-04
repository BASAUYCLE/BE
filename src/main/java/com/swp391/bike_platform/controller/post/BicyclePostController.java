package com.swp391.bike_platform.controller.post;

import com.swp391.bike_platform.request.BicyclePostCreateRequest;
import com.swp391.bike_platform.request.BicyclePostUpdateRequest;
import com.swp391.bike_platform.response.BicyclePostResponse;
import com.swp391.bike_platform.service.BicyclePostService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;

@RestController
@RequestMapping("/posts")
@RequiredArgsConstructor
public class BicyclePostController {

    private final BicyclePostService bicyclePostService;

    @PostMapping
    public BicyclePostResponse createPost(@RequestBody BicyclePostCreateRequest request) {
        return bicyclePostService.createPost(request);
    }

    // ============ ENDPOINTS FOR CURRENT USER ============

    @GetMapping("/my-posts")
    public List<BicyclePostResponse> getMyPosts(@AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        return bicyclePostService.getMyPosts(userId);
    }

    @PostMapping("/draft")
    public BicyclePostResponse createDraftPost(@AuthenticationPrincipal Jwt jwt,
            @RequestBody BicyclePostCreateRequest request) {
        Long userId = jwt.getClaim("userId");
        return bicyclePostService.createDraftPost(userId, request);
    }

    @GetMapping("/drafts")
    public List<BicyclePostResponse> getMyDrafts(@AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        return bicyclePostService.getMyDrafts(userId);
    }

    // ============ PUBLIC ENDPOINTS ============

    @GetMapping
    public List<BicyclePostResponse> getAllPosts() {
        return bicyclePostService.getAllPosts();
    }

    @GetMapping("/{postId}")
    public BicyclePostResponse getPostById(@PathVariable Long postId) {
        return bicyclePostService.getPostById(postId);
    }

    @GetMapping("/seller/{sellerId}")
    public List<BicyclePostResponse> getPostsBySellerId(@PathVariable Long sellerId) {
        return bicyclePostService.getPostsBySellerId(sellerId);
    }

    @GetMapping("/brand/{brandId}")
    public List<BicyclePostResponse> getPostsByBrandId(@PathVariable Long brandId) {
        return bicyclePostService.getPostsByBrandId(brandId);
    }

    @GetMapping("/category/{categoryId}")
    public List<BicyclePostResponse> getPostsByCategoryId(@PathVariable Long categoryId) {
        return bicyclePostService.getPostsByCategoryId(categoryId);
    }

    @GetMapping("/size/{size}")
    public List<BicyclePostResponse> getPostsBySize(@PathVariable String size) {
        return bicyclePostService.getPostsBySize(size);
    }

    // REMOVED: /status/{status} endpoint - Security risk! Admin should use
    // /admin/posts/status/{status}

    @GetMapping("/search")
    public List<BicyclePostResponse> searchPosts(
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice) {
        if (minPrice != null && maxPrice != null) {
            return bicyclePostService.getPostsByPriceRange(minPrice, maxPrice);
        }
        return bicyclePostService.getAllPosts();
    }

    @PutMapping("/{postId}")
    public BicyclePostResponse updatePost(@PathVariable Long postId,
            @RequestBody BicyclePostUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        return bicyclePostService.updatePost(postId, userId, request);
    }

    @DeleteMapping("/{postId}")
    public String deletePost(@PathVariable Long postId, @AuthenticationPrincipal Jwt jwt) {
        Long userId = jwt.getClaim("userId");
        bicyclePostService.deletePost(postId, userId);
        return "Bicycle post has been deleted";
    }
}
