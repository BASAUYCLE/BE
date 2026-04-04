package com.swp391.bike_platform.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "InspectionReports")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InspectionReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "report_id")
    private Long reportId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private BicyclePost post;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inspector_id", nullable = false)
    private User inspector;

    // PASS or FAIL (do BE tự tính)
    @Column(name = "inspection_result", nullable = false, length = 20)
    private String inspectionResult;

    // EXCELLENT, GOOD, FAIR, POOR (do BE tự gán)
    @Column(name = "overall_condition", length = 50)
    private String overallCondition;

    // 6 tiêu chí chấm điểm (0-10)
    @Column(name = "color_score", nullable = false)
    private Integer colorScore;

    @Column(name = "frame_score", nullable = false)
    private Integer frameScore;

    @Column(name = "groupset_score", nullable = false)
    private Integer groupsetScore;

    @Column(name = "brake_score", nullable = false)
    private Integer brakeScore;

    @Column(name = "control_score", nullable = false)
    private Integer controlScore;

    @Column(name = "wheel_score", nullable = false)
    private Integer wheelScore;

    // Phần trăm tình trạng xe (tính từ trọng số)
    @Column(name = "condition_percent", nullable = false)
    private Double conditionPercent;

    // Ghi chú từ Inspector
    @Column(name = "notes", columnDefinition = "NVARCHAR(MAX)")
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
