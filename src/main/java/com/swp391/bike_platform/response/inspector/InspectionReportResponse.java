package com.swp391.bike_platform.response.inspector;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InspectionReportResponse {

    private Long reportId;
    private Long postId;
    private Long inspectorId;
    private String inspectorName;
    private String result; // PASS or FAIL
    private String overallCondition; // Excellent, Good, Fair, Poor
    private String notes;
    private String postStatus; // AVAILABLE or REJECTED
    private LocalDateTime createdAt;
}
