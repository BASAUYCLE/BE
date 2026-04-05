package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.BicycleImage;
import com.swp391.bike_platform.entity.BicyclePost;
import com.swp391.bike_platform.entity.InspectionReport;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.entity.Wallet;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.enums.InspectionResult;
import com.swp391.bike_platform.enums.PostStatus;
import com.swp391.bike_platform.enums.TransactionType;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BicycleImageRepository;
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

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class InspectionService {

    private final BicyclePostRepository bicyclePostRepository;
    private final BicycleImageRepository bicycleImageRepository;
    private final InspectionReportRepository inspectionReportRepository;
    private final UserRepository userRepository;
    private final WalletService walletService;
    private final TransactionService transactionService;
    private final SystemConfigService systemConfigService;
    private final CloudinaryService cloudinaryService;

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
     * Inspector nộp kết quả kiểm định với 6 tiêu chí chấm điểm.
     * BE tự tính conditionPercent, gán nhãn overallCondition, xác định PASS/FAIL.
     * Hoàn phí đăng bài cho seller trong mọi trường hợp (cả PASS lẫn FAIL).
     */
    @Transactional
    public InspectionReportResponse submitInspection(Long postId, InspectionRequest request, String inspectorEmail) {
        // Validate điểm chỉ cho phép 0, 3, 7, 10
        validateScores(request);

        // Tìm post
        BicyclePost post = bicyclePostRepository.findById(postId)
                .orElseThrow(() -> new AppException(ErrorCode.POST_NOT_EXISTED));

        if (!PostStatus.ADMIN_APPROVED.name().equals(post.getPostStatus())) {
            throw new AppException(ErrorCode.INVALID_POST_STATUS);
        }

        // Tìm inspector
        User inspector = userRepository.findByEmail(inspectorEmail)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        // Tính conditionPercent theo trọng số
        double conditionPercent = calculateConditionPercent(request);

        // Xe cũ không thể đạt 100% — tự động trừ xuống 99%
        if (conditionPercent >= 100.0) {
            conditionPercent = 99.0;
        }

        // Gán nhãn overallCondition
        String overallCondition = determineOverallCondition(conditionPercent);

        // Xác định PASS/FAIL
        InspectionResult result = determineResult(conditionPercent, request.getFrameScore(), request.getBrakeScore());

        // Update post status
        String newPostStatus = (result == InspectionResult.PASS) ? PostStatus.AVAILABLE.name()
                : PostStatus.REJECTED.name();
        post.setPostStatus(newPostStatus);
        bicyclePostRepository.save(post);

        // Apply watermark to all images when inspection PASS
        if (result == InspectionResult.PASS) {
            List<BicycleImage> images = bicycleImageRepository.findByPost_PostId(postId);
            LocalDateTime now = LocalDateTime.now();
            for (BicycleImage img : images) {
                String watermarkedUrl = cloudinaryService.addWatermark(
                        img.getImageUrl(), inspector.getFullName(), now);
                img.setImageUrl(watermarkedUrl);
            }
            bicycleImageRepository.saveAll(images);
            log.info("Watermark applied to {} images for post {}", images.size(), postId);
        }

        // Create inspection report
        InspectionReport report = InspectionReport.builder()
                .post(post)
                .inspector(inspector)
                .inspectionResult(result.name())
                .overallCondition(overallCondition)
                .colorScore(request.getColorScore())
                .frameScore(request.getFrameScore())
                .groupsetScore(request.getGroupsetScore())
                .brakeScore(request.getBrakeScore())
                .controlScore(request.getControlScore())
                .wheelScore(request.getWheelScore())
                .conditionPercent(conditionPercent)
                .notes(request.getNotes())
                .build();

        InspectionReport savedReport = inspectionReportRepository.save(report);

        // Hoàn phí đăng bài cho seller (bất kể PASS hay FAIL)
        refundPostingFee(post.getSeller(), post);

        log.info("Inspection submitted for post {}: result={}, conditionPercent={}%, overallCondition={}, newStatus={}",
                postId, result, conditionPercent, overallCondition, newPostStatus);

        return toReportResponse(savedReport, newPostStatus);
    }

    /**
     * Validate điểm kiểm định: chỉ cho phép 0, 3, 7, 10.
     * 10 = Như mới, không có dấu hiệu sử dụng nhiều
     * 7 = Nguyên bản, có dấu hiệu sử dụng nhẹ
     * 3 = Có dấu hiệu thay thế hoặc chỉnh sửa
     * 0 = Hư hỏng nặng, khả năng sử dụng thấp
     */
    private void validateScores(InspectionRequest request) {
        java.util.Set<Integer> allowedScores = java.util.Set.of(0, 3, 7, 10);

        if (!allowedScores.contains(request.getColorScore())
                || !allowedScores.contains(request.getFrameScore())
                || !allowedScores.contains(request.getGroupsetScore())
                || !allowedScores.contains(request.getBrakeScore())
                || !allowedScores.contains(request.getControlScore())
                || !allowedScores.contains(request.getWheelScore())) {
            throw new AppException(ErrorCode.INVALID_INSPECTION_SCORE);
        }
    }

    /**
     * Tính phần trăm tình trạng xe theo trọng số 6 tiêu chí.
     * Công thức: (color×0.10 + frame×0.30 + groupset×0.25 + brake×0.15 +
     * control×0.10 + wheel×0.10) × 10
     */
    private double calculateConditionPercent(InspectionRequest request) {
        return (request.getColorScore() * 0.10
                + request.getFrameScore() * 0.30
                + request.getGroupsetScore() * 0.25
                + request.getBrakeScore() * 0.15
                + request.getControlScore() * 0.10
                + request.getWheelScore() * 0.10) * 10;
    }

    /**
     * Gán nhãn tình trạng xe dựa trên conditionPercent.
     */
    private String determineOverallCondition(double conditionPercent) {
        if (conditionPercent >= 90)
            return "EXCELLENT";
        if (conditionPercent >= 70)
            return "GOOD";
        if (conditionPercent >= 50)
            return "FAIR";
        return "POOR";
    }

    /**
     * Xác định kết quả kiểm định.
     * Auto FAIL nếu: conditionPercent < 50 HOẶC frameScore == 0 HOẶC brakeScore ==
     * 0
     */
    private InspectionResult determineResult(double conditionPercent, int frameScore, int brakeScore) {
        if (conditionPercent < 50 || frameScore == 0 || brakeScore == 0) {
            return InspectionResult.FAIL;
        }
        return InspectionResult.PASS;
    }

    /**
     * Admin: Lấy toàn bộ lịch sử inspector duyệt bài
     */
    public List<InspectionReportResponse> getApprovalHistory() {
        return inspectionReportRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(r -> toReportResponse(r, r.getPost().getPostStatus()))
                .collect(Collectors.toList());
    }

    /**
     * Inspector: Lấy lịch sử duyệt bài của mình
     */
    public List<InspectionReportResponse> getMyApprovalHistory(String inspectorEmail) {
        User inspector = userRepository.findByEmail(inspectorEmail)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
        return inspectionReportRepository.findByInspector_UserId(inspector.getUserId()).stream()
                .map(r -> toReportResponse(r, r.getPost().getPostStatus()))
                .collect(Collectors.toList());
    }

    /**
     * Public: Lấy phiếu kiểm định cho mọi người xem.
     * - PASS: tất cả mọi người đều xem được.
     * - FAIL: chỉ người đăng bán xe (seller) mới xem được.
     *
     * @param currentUserEmail email của user đang đăng nhập (null nếu anonymous)
     */
    public List<InspectionReportResponse> getPublicReports(String currentUserEmail) {
        // Lấy tất cả report PASS — ai cũng xem được
        List<InspectionReport> passReports = inspectionReportRepository
                .findByInspectionResultOrderByCreatedAtDesc(InspectionResult.PASS.name());

        List<InspectionReportResponse> result = passReports.stream()
                .map(r -> toReportResponse(r, r.getPost().getPostStatus()))
                .collect(Collectors.toList());

        // Nếu user đã đăng nhập, thêm các report FAIL của bài đăng mà user là seller
        if (currentUserEmail != null && !currentUserEmail.isBlank()) {
            List<InspectionReport> failReports = inspectionReportRepository
                    .findByInspectionResultAndPost_Seller_EmailOrderByCreatedAtDesc(
                            InspectionResult.FAIL.name(), currentUserEmail);

            failReports.stream()
                    .map(r -> toReportResponse(r, r.getPost().getPostStatus()))
                    .forEach(result::add);
        }

        return result;
    }

    /**
     * Hoàn phí đăng bài vào ví người bán và tạo transaction REFUND
     */
    private void refundPostingFee(User seller, BicyclePost post) {
        BigDecimal postingFee = systemConfigService.getPostingFee();
        Wallet sellerWallet = walletService.getOrCreateWallet(seller.getUserId());

        walletService.addBalance(sellerWallet.getWalletId(), postingFee);

        transactionService.createOrderTransaction(
                sellerWallet, seller, post,
                TransactionType.REFUND, postingFee,
                "+" + TransactionService.formatAmount(postingFee) + " VND - Hoàn phí đăng bài (kiểm định hoàn tất)");
    }

    private InspectionReportResponse toReportResponse(InspectionReport report, String postStatus) {
        return InspectionReportResponse.builder()
                .reportId(report.getReportId())
                .postId(report.getPost().getPostId())
                .postTitle(report.getPost().getBicycleName())
                .inspectorId(report.getInspector().getUserId())
                .inspectorName(report.getInspector().getFullName())
                .inspectorEmail(report.getInspector().getEmail())
                .result(report.getInspectionResult())
                .overallCondition(report.getOverallCondition())
                .colorScore(report.getColorScore())
                .frameScore(report.getFrameScore())
                .groupsetScore(report.getGroupsetScore())
                .brakeScore(report.getBrakeScore())
                .controlScore(report.getControlScore())
                .wheelScore(report.getWheelScore())
                .conditionPercent(report.getConditionPercent())
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
                .sellerAvatarUrl(post.getSeller().getAvatarUrl())
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
                .sellerAvatarUrl(post.getSeller().getAvatarUrl())
                .createdAt(post.getCreatedAt())
                .build();
    }
}
