package com.swp391.bike_platform.controller.inspector;

import com.swp391.bike_platform.request.InspectionRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.BicyclePostSummaryResponse;
import com.swp391.bike_platform.response.inspector.InspectionReportResponse;
import com.swp391.bike_platform.service.InspectionService;
import jakarta.validation.Valid;
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
    public ApiResponse<List<BicyclePostSummaryResponse>> getPendingInspections() {
        return ApiResponse.<List<BicyclePostSummaryResponse>>builder()
                .result(inspectionService.getPostsAwaitingInspection())
                .build();
    }

    /**
     * POST /inspection/{postId}/submit
     * Inspector nộp kết quả kiểm định với 6 tiêu chí chấm điểm (0-10)
     */
    @PostMapping("/{postId}/submit")
    public ApiResponse<InspectionReportResponse> submitInspection(
            @PathVariable Long postId,
            @Valid @RequestBody InspectionRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        String inspectorEmail = jwt.getSubject();
        return ApiResponse.<InspectionReportResponse>builder()
                .result(inspectionService.submitInspection(postId, request, inspectorEmail))
                .build();
    }

    /**
     * GET /inspection/reports
     * Inspector xem toàn bộ lịch sử duyệt bài của mình
     */
    @GetMapping("/reports")
    public ApiResponse<List<InspectionReportResponse>> getMyApprovalHistory(
            @AuthenticationPrincipal Jwt jwt) {
        String inspectorEmail = jwt.getSubject();
        return ApiResponse.<List<InspectionReportResponse>>builder()
                .result(inspectionService.getMyApprovalHistory(inspectorEmail))
                .build();
    }
}
