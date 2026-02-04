package com.swp391.bike_platform.controller.inspector;

import com.swp391.bike_platform.request.InspectionRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.BicyclePostResponse;
import com.swp391.bike_platform.response.inspector.InspectionReportResponse;
import com.swp391.bike_platform.service.InspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/inspection")
@RequiredArgsConstructor
public class InspectionController {

    private final InspectionService inspectionService;

    /**
     * GET /inspection/pending
     * Lấy danh sách bài đăng chờ Inspector kiểm định (ADMIN_APPROVED)
     */
    @GetMapping("/pending")
    public ApiResponse<List<BicyclePostResponse>> getPendingInspections() {
        return ApiResponse.<List<BicyclePostResponse>>builder()
                .result(inspectionService.getPostsAwaitingInspection())
                .build();
    }

    /**
     * POST /inspection/{postId}/submit
     * Inspector nộp kết quả kiểm định
     */
    @PostMapping("/{postId}/submit")
    public ApiResponse<InspectionReportResponse> submitInspection(
            @PathVariable Long postId,
            @RequestBody InspectionRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        String inspectorEmail = jwt.getSubject();
        return ApiResponse.<InspectionReportResponse>builder()
                .result(inspectionService.submitInspection(postId, request, inspectorEmail))
                .build();
    }
}
