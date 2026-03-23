package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.inspector.InspectionReportResponse;
import com.swp391.bike_platform.service.InspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/admin/inspection")
@RequiredArgsConstructor
public class AdminInspectionController {

    private final InspectionService inspectionService;

    /**
     * GET /admin/inspection/reports
     * Lấy toàn bộ lịch sử duyệt bài của các Inspector
     */
    @GetMapping("/reports")
    public ApiResponse<List<InspectionReportResponse>> getApprovalHistory() {
        return ApiResponse.<List<InspectionReportResponse>>builder()
                .result(inspectionService.getApprovalHistory())
                .build();
    }
}
