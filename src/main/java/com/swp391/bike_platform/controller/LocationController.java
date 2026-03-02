package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.CommuneResponse;
import com.swp391.bike_platform.response.ProvinceResponse;
import com.swp391.bike_platform.service.LocationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/locations")
@RequiredArgsConstructor
public class LocationController {

    private final LocationService locationService;

    /**
     * GET /locations/provinces — danh sách tỉnh/thành
     */
    @GetMapping("/provinces")
    public ApiResponse<List<ProvinceResponse>> getAllProvinces() {
        return ApiResponse.<List<ProvinceResponse>>builder()
                .result(locationService.getAllProvinces())
                .build();
    }

    /**
     * GET /locations/provinces/{code}/communes — danh sách xã/phường theo tỉnh
     */
    @GetMapping("/provinces/{provinceCode}/communes")
    public ApiResponse<List<CommuneResponse>> getCommunesByProvince(@PathVariable String provinceCode) {
        return ApiResponse.<List<CommuneResponse>>builder()
                .result(locationService.getCommunesByProvince(provinceCode))
                .build();
    }
}
