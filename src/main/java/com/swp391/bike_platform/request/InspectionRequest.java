package com.swp391.bike_platform.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InspectionRequest {

    // PASS hoặc FAIL
    private String result;

    // Excellent, Good, Fair, Poor
    private String overallCondition;

    // Ghi chú từ Inspector
    private String notes;
}
