package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.request.CreateDisputeRequest;
import com.swp391.bike_platform.request.NoteRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.DisputeResponse;
import com.swp391.bike_platform.service.DisputeService;
import com.swp391.bike_platform.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.swp391.bike_platform.request.UpdateShippingInfoRequest;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/disputes")
@RequiredArgsConstructor
public class DisputeController {

        private final DisputeService disputeService;
        private final UserService userService;

        private Long getCurrentUserId(Jwt jwt) {
                User user = userService.getUserEntityByEmail(jwt.getSubject());
                return user.getUserId();
        }

        @PostMapping
        public ApiResponse<DisputeResponse> createDispute(@AuthenticationPrincipal Jwt jwt,
                        @ModelAttribute CreateDisputeRequest request) throws IOException {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.createDispute(getCurrentUserId(jwt), request))
                                .build();
        }

        @GetMapping("/{id}")
        public ApiResponse<DisputeResponse> getDisputeById(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id) {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.getDisputeById(id, getCurrentUserId(jwt)))
                                .build();
        }

        @GetMapping("/my-disputes")
        public ApiResponse<List<DisputeResponse>> getMyDisputes(@AuthenticationPrincipal Jwt jwt) {
                return ApiResponse.<List<DisputeResponse>>builder()
                                .result(disputeService.getMyDisputes(getCurrentUserId(jwt)))
                                .build();
        }

        @PutMapping("/{id}/inspector-note")
        public ApiResponse<DisputeResponse> addInspectorNote(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id,
                        @RequestBody NoteRequest request) {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.addInspectorNote(id, getCurrentUserId(jwt), request))
                                .build();
        }

        // ─────────────────── ADMIN: GET ALL DISPUTES ───────────────────

        @GetMapping("/admin/all")
        public ApiResponse<List<DisputeResponse>> getAllDisputes() {
                return ApiResponse.<List<DisputeResponse>>builder()
                                .result(disputeService.getAllDisputes())
                                .build();
        }

        // ─────────────────── INSPECTOR: GET MY DISPUTES(POST THAT I APPROVE)
        // ───────────────────

        @GetMapping("/inspector/my-disputes")
        public ApiResponse<List<DisputeResponse>> getInspectorDisputes(@AuthenticationPrincipal Jwt jwt) {
                return ApiResponse.<List<DisputeResponse>>builder()
                                .result(disputeService.getDisputesByInspector(getCurrentUserId(jwt)))
                                .build();
        }

        // ─────────────────── ADMIN ENDPOINTS ───────────────────

        @PutMapping("/admin/{id}/approve")
        public ApiResponse<DisputeResponse> approveDispute(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id,
                        @RequestBody(required = false) NoteRequest request) {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.approveDispute(id, getCurrentUserId(jwt), request))
                                .build();
        }

        @PutMapping("/admin/{id}/reject")
        public ApiResponse<DisputeResponse> rejectDispute(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id,
                        @RequestBody(required = false) NoteRequest request) {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.rejectDisputeByAdmin(id, getCurrentUserId(jwt), request))
                                .build();
        }

        // ─────────────────── BUYER / SELLER ENDPOINTS ───────────────────

        @PutMapping("/{id}/shipping-info")
        public ApiResponse<DisputeResponse> updateShippingInfo(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id,
                        @RequestBody UpdateShippingInfoRequest request) {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.updateShippingInfo(id, getCurrentUserId(jwt), request))
                                .build();
        }

        @PutMapping("/{id}/confirm-return-receipt")
        public ApiResponse<DisputeResponse> confirmReturnReceipt(@AuthenticationPrincipal Jwt jwt,
                        @PathVariable Long id) {
                return ApiResponse.<DisputeResponse>builder()
                                .result(disputeService.confirmReturnReceipt(id, getCurrentUserId(jwt)))
                                .build();
        }
}
