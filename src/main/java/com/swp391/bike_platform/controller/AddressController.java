package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.request.AddressRequest;
import com.swp391.bike_platform.response.AddressResponse;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.service.AddressService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users/{userId}/addresses")
@RequiredArgsConstructor
public class AddressController {

    private final AddressService addressService;

    /**
     * GET /users/{userId}/addresses — danh sách địa chỉ
     */
    @GetMapping
    public ApiResponse<List<AddressResponse>> getUserAddresses(@PathVariable Long userId) {
        return ApiResponse.<List<AddressResponse>>builder()
                .result(addressService.getUserAddresses(userId))
                .build();
    }

    /**
     * GET /users/{userId}/addresses/{addressId}
     */
    @GetMapping("/{addressId}")
    public ApiResponse<AddressResponse> getAddressById(@PathVariable Long userId, @PathVariable Long addressId) {
        return ApiResponse.<AddressResponse>builder()
                .result(addressService.getAddressById(userId, addressId))
                .build();
    }

    /**
     * POST /users/{userId}/addresses — tạo mới
     */
    @PostMapping
    public ApiResponse<AddressResponse> createAddress(@PathVariable Long userId, @RequestBody AddressRequest request) {
        return ApiResponse.<AddressResponse>builder()
                .result(addressService.createAddress(userId, request))
                .message("Address created successfully")
                .build();
    }

    /**
     * PUT /users/{userId}/addresses/{addressId} — cập nhật
     */
    @PutMapping("/{addressId}")
    public ApiResponse<AddressResponse> updateAddress(@PathVariable Long userId, @PathVariable Long addressId,
            @RequestBody AddressRequest request) {
        return ApiResponse.<AddressResponse>builder()
                .result(addressService.updateAddress(userId, addressId, request))
                .message("Address updated successfully")
                .build();
    }

    /**
     * DELETE /users/{userId}/addresses/{addressId}
     */
    @DeleteMapping("/{addressId}")
    public ApiResponse<Void> deleteAddress(@PathVariable Long userId, @PathVariable Long addressId) {
        addressService.deleteAddress(userId, addressId);
        return ApiResponse.<Void>builder()
                .message("Address deleted successfully")
                .build();
    }
}
