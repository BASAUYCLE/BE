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
    private String postTitle;
    private Long sellerId;
    private String sellerName;
    private String sellerAvatarUrl;
    private Long inspectorId;
    private String inspectorName;
    private String inspectorEmail;
    private String inspectorAvatarUrl;
    private String result; // PASS or FAIL
    private String overallCondition; // EXCELLENT, GOOD, FAIR, POOR

    // 6 tiêu chí chấm điểm
    private Integer colorScore;
    private Integer frameScore;
    private Integer groupsetScore;
    private Integer brakeScore;
    private Integer controlScore;
    private Integer wheelScore;

    // Phần trăm tình trạng
    private Double conditionPercent;

    private String notes;
    private String postStatus; // AVAILABLE or REJECTED
    private LocalDateTime createdAt;
}
