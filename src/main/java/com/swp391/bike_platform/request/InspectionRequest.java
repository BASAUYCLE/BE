package com.swp391.bike_platform.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InspectionRequest {

    // Chỉ cho phép: 0, 3, 7, 10
    // 10 = Như mới, không có dấu hiệu sử dụng nhiều
    //  7 = Nguyên bản, có dấu hiệu sử dụng nhẹ
    //  3 = Có dấu hiệu thay thế hoặc chỉnh sửa
    //  0 = Hư hỏng nặng, khả năng sử dụng thấp

    @NotNull
    private Integer colorScore;

    @NotNull
    private Integer frameScore;

    @NotNull
    private Integer groupsetScore;

    @NotNull
    private Integer brakeScore;

    @NotNull
    private Integer controlScore;

    @NotNull
    private Integer wheelScore;

    // Ghi chú từ Inspector
    private String notes;
}
