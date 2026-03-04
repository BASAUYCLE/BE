package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.request.UpdateConfigRequest;
import com.swp391.bike_platform.response.ApiResponse;
import com.swp391.bike_platform.response.SystemConfigResponse;
import com.swp391.bike_platform.service.SystemConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/config")
@RequiredArgsConstructor
public class AdminConfigController {

    private final SystemConfigService systemConfigService;

    /**
     * GET /admin/config — Get all system configurations
     */
    @GetMapping
    public ApiResponse<List<SystemConfigResponse>> getAllConfigs() {
        return ApiResponse.<List<SystemConfigResponse>>builder()
                .result(systemConfigService.getAllConfigs())
                .build();
    }

    /**
     * GET /admin/config/{key} — Get a single config by key
     */
    @GetMapping("/{key}")
    public ApiResponse<SystemConfigResponse> getConfig(@PathVariable String key) {
        return ApiResponse.<SystemConfigResponse>builder()
                .result(systemConfigService.getConfig(key))
                .build();
    }

    /**
     * PUT /admin/config/{key} — Update config value
     */
    @PutMapping("/{key}")
    public ApiResponse<SystemConfigResponse> updateConfig(@PathVariable String key,
            @RequestBody UpdateConfigRequest request) {
        return ApiResponse.<SystemConfigResponse>builder()
                .result(systemConfigService.updateConfig(key, request.getConfigValue()))
                .message("Config updated successfully")
                .build();
    }
}
