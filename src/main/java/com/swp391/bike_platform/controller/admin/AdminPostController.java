package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.BicyclePostResponse;
import com.swp391.bike_platform.service.AdminPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/posts")
@RequiredArgsConstructor
public class AdminPostController {

    private final AdminPostService adminPostService;

    /**
     * GET /admin/posts/pending
     * Lấy danh sách bài đăng chờ Admin duyệt
     */
    @GetMapping("/pending")
    public ApiResponse<List<BicyclePostResponse>> getPendingPosts() {
        return ApiResponse.<List<BicyclePostResponse>>builder()
                .result(adminPostService.getPendingPosts())
                .build();
    }

    /**
     * PUT /admin/posts/{postId}/approve
     * Admin duyệt bài đăng -> ADMIN_APPROVED
     */
    @PutMapping("/{postId}/approve")
    public ApiResponse<BicyclePostResponse> approvePost(@PathVariable Long postId) {
        return ApiResponse.<BicyclePostResponse>builder()
                .result(adminPostService.approvePost(postId))
                .build();
    }

    /**
     * PUT /admin/posts/{postId}/reject
     * Admin từ chối bài đăng -> REJECTED
     */
    @PutMapping("/{postId}/reject")
    public ApiResponse<BicyclePostResponse> rejectPost(@PathVariable Long postId) {
        return ApiResponse.<BicyclePostResponse>builder()
                .result(adminPostService.rejectPost(postId))
                .build();
    }
}
