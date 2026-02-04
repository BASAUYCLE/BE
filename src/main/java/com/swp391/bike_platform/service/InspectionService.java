package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.InspectionReport;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.InspectionResult;
import com.swp391.bike_platform.enums.PostStatus;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicyclePostRepository;
import com.swp391.bike_platform.repository.InspectionReportRepository;
import com.swp391.bike_platform.repository.UserRepository;
import com.swp391.bike_platform.request.InspectionRequest;
import com.swp391.bike_platform.response.BicyclePostResponse;
import com.swp391.bike_platform.response.BicyclePostSummaryResponse;
import com.swp391.bike_platform.response.inspector.InspectionReportResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InspectionService {

    private final BicyclePostRepository bicyclePostRepository;
    private final InspectionReportRepository inspectionReportRepository;
    private final UserRepository userRepository;

    /**
     * Lấy danh sách bài đăng chờ Inspector kiểm định (status = ADMIN_APPROVED)
     */
    public List<BicyclePostSummaryResponse> getPostsAwaitingInspection() {
        List<BicyclePost> posts = bicyclePostRepository.findByPostStatus(PostStatus.ADMIN_APPROVED.name());
        return posts.stream()
                .map(this::toSummaryResponse)
                .collect(Collectors.toList());
    }

    /**
     * Inspector nộp kết quả kiểm định
     * - PASS -> post status = AVAILABLE
     * - FAIL -> post status = REJECTED
     */
    @Transactional
    public InspectionReportResponse submitInspection(Long postId, InspectionRequest request, String inspectorEmail) {
        // Tìm post
        BicyclePost post = bicyclePostRepository.findById(postId)
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));

        if (!PostStatus.ADMIN_APPROVED.name().equals(post.getPostStatus())) {
            throw new AppException(ErrorCode.INVALID_POST_STATUS);
        }

        // Tìm inspector
        User inspector = userRepository.findByEmail(inspectorEmail)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        // Validate result
        String resultStr = request.getResult().toUpperCase();
        InspectionResult result;
        try {
            result = InspectionResult.valueOf(resultStr);
        } catch (IllegalArgumentException e) {
            throw new AppException(ErrorCode.MISSING_REQUIRED_FIELD);
        }

        // Update post status
        String newPostStatus = (result == InspectionResult.PASS) ? PostStatus.AVAILABLE.name()
                : PostStatus.REJECTED.name();
        post.setPostStatus(newPostStatus);
        bicyclePostRepository.save(post);

        // Create inspection report
        InspectionReport report = InspectionReport.builder()
                .post(post)
                .inspector(inspector)
                .inspectionResult(result.name())
                .overallCondition(request.getOverallCondition())
                .notes(request.getNotes())
                .build();

        InspectionReport savedReport = inspectionReportRepository.save(report);

        log.info("Inspection submitted for post {}: result={}, newStatus={}", postId, result, newPostStatus);

        return toReportResponse(savedReport, newPostStatus);
    }

    private InspectionReportResponse toReportResponse(InspectionReport report, String postStatus) {
        return InspectionReportResponse.builder()
                .reportId(report.getReportId())
                .postId(report.getPost().getPostId())
                .inspectorId(report.getInspector().getUserId())
                .inspectorName(report.getInspector().getFullName())
                .result(report.getInspectionResult())
                .overallCondition(report.getOverallCondition())
                .notes(report.getNotes())
                .postStatus(postStatus)
                .createdAt(report.getCreatedAt())
                .build();
    }

    private BicyclePostResponse toPostResponse(BicyclePost post) {
        return BicyclePostResponse.builder()
                .postId(post.getPostId())
                .sellerId(post.getSeller().getUserId())
                .sellerFullName(post.getSeller().getFullName())
                .sellerPhoneNumber(post.getSeller().getPhoneNumber())
                .brandId(post.getBrand().getBrandId())
                .brandName(post.getBrand().getBrandName())
                .categoryId(post.getCategory().getCategoryId())
                .categoryName(post.getCategory().getCategoryName())
                .bicycleName(post.getBicycleName())
                .bicycleColor(post.getBicycleColor())
                .price(post.getPrice())
                .bicycleDescription(post.getBicycleDescription())
                .groupset(post.getGroupset())
                .frameMaterial(post.getFrameMaterial())
                .brakeType(post.getBrakeType())
                .size(post.getSize())
                .modelYear(post.getModelYear())
                .postStatus(post.getPostStatus())
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .build();
    }

    private BicyclePostSummaryResponse toSummaryResponse(BicyclePost post) {
        // Find thumbnail if exists, otherwise first image, otherwise null
        String thumbnail = post.getImages().stream()
                .filter(img -> Boolean.TRUE.equals(img.getIsThumbnail()))
                .map(com.swp391.bike_platform.entity.BicycleImage::getImageUrl)
                .findFirst()
                .orElse(post.getImages().isEmpty() ? null : post.getImages().get(0).getImageUrl());

        return BicyclePostSummaryResponse.builder()
                .postId(post.getPostId())
                .bicycleName(post.getBicycleName())
                .price(post.getPrice())
                .brandName(post.getBrand().getBrandName())
                .categoryName(post.getCategory().getCategoryName())
                .size(post.getSize())
                .postStatus(post.getPostStatus())
                .thumbnailUrl(thumbnail)
                .sellerFullName(post.getSeller().getFullName())
                .createdAt(post.getCreatedAt())
                .build();
    }
}
