package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.InspectionReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InspectionReportRepository extends JpaRepository<InspectionReport, Long> {

    // Tìm report theo post
    Optional<InspectionReport> findByPost_PostId(Long postId);

    // Tìm tất cả reports của một inspector
    List<InspectionReport> findByInspector_UserId(Long inspectorId);

    // Kiểm tra post đã có report chưa
    boolean existsByPost_PostId(Long postId);
}
