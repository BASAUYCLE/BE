package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.request.BrandCreateRequest;
import com.swp391.bike_platform.request.BrandUpdateRequest;
import com.swp391.bike_platform.response.admin.BrandResponse;
import com.swp391.bike_platform.service.BrandService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/brands")
@RequiredArgsConstructor
public class BrandController {
    private final BrandService brandService;

    @PostMapping
    BrandResponse createBrand(@ModelAttribute BrandCreateRequest request) {
        return brandService.createBrand(request);
    }

    @GetMapping
    List<BrandResponse> getAllBrands() {
        return brandService.getAllBrands();
    }

    @GetMapping("/{brandId}")
    BrandResponse getBrandById(@PathVariable Long brandId) {
        return brandService.getBrandById(brandId);
    }

    @PutMapping("/{brandId}")
    BrandResponse updateBrand(@PathVariable Long brandId,
            @ModelAttribute BrandUpdateRequest request) {
        return brandService.updateBrand(brandId, request);
    }

    @DeleteMapping("/{brandId}")
    String deleteBrand(@PathVariable Long brandId) {
        brandService.deleteBrand(brandId);
        return "Brand has been deleted";
    }
}
