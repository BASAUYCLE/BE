package com.swp391.bike_platform.controller.inspector;

import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.inspector.InspectionReportResponse;
import com.swp391.bike_platform.service.InspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class PublicInspectionController {

    private final InspectionService inspectionService;

    /**
     * GET /reports/inspection
     * Lấy danh sách phiếu kiểm định:
     * - PASS: tất cả mọi người đều xem được
     * - FAIL: chỉ seller (người đăng bán xe đó) mới xem được
     *
     * Endpoint này cho phép cả anonymous và authenticated user truy cập.
     * Nếu đã đăng nhập, các report FAIL của bài đăng thuộc user đó cũng sẽ được trả về.
     */
    @GetMapping("/inspection")
    public ApiResponse<List<InspectionReportResponse>> getPublicReports(
            @AuthenticationPrincipal Jwt jwt) {

        String currentUserEmail = (jwt != null) ? jwt.getSubject() : null;

        return ApiResponse.<List<InspectionReportResponse>>builder()
                .result(inspectionService.getPublicReports(currentUserEmail))
                .build();
    }
}
