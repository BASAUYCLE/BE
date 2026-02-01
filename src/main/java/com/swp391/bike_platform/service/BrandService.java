package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.Brand;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.BrandRepository;
import com.swp391.bike_platform.request.BrandCreateRequest;
import com.swp391.bike_platform.request.BrandUpdateRequest;
import com.swp391.bike_platform.response.admin.BrandResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BrandService {
    private final BrandRepository brandRepository;
    private final CloudinaryService cloudinaryService;

    public BrandResponse createBrand(BrandCreateRequest request) {
        log.info("Creating brand: {}", request.getBrandName());

        if (brandRepository.existsByBrandName(request.getBrandName())) {
            throw new AppException(ErrorCode.BRAND_EXISTED);
        }

        Brand brand = new Brand();
        brand.setBrandName(request.getBrandName().trim());

        // Upload brand logo to Cloudinary
        try {
            if (request.getBrandLogo() != null && !request.getBrandLogo().isEmpty()) {
                log.info("Uploading brand logo to Cloudinary...");
                String logoUrl = cloudinaryService.uploadImage(request.getBrandLogo());
                log.info("Brand logo uploaded successfully: {}", logoUrl);
                brand.setBrandLogoUrl(logoUrl);
            }
        } catch (java.io.IOException e) {
            log.error("Failed to upload brand logo: {}", e.getMessage());
            throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
        }

        if (request.getBrandOriginCountry() != null) {
            brand.setBrandOriginCountry(request.getBrandOriginCountry().trim());
        }

        Brand savedBrand = brandRepository.save(brand);
        log.info("Brand saved with logo URL: {}", savedBrand.getBrandLogoUrl());

        return toBrandResponse(savedBrand);
    }

    public List<BrandResponse> getAllBrands() {
        return brandRepository.findAll().stream()
                .map(this::toBrandResponse)
                .collect(Collectors.toList());
    }

    public BrandResponse getBrandById(Long id) {
        return toBrandResponse(brandRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.BRAND_NOT_EXISTED)));
    }

    public BrandResponse updateBrand(Long id, BrandUpdateRequest request) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.BRAND_NOT_EXISTED));

        if (request.getBrandName() != null) {
            if (!brand.getBrandName().equals(request.getBrandName())
                    && brandRepository.existsByBrandName(request.getBrandName())) {
                throw new AppException(ErrorCode.BRAND_EXISTED);
            }
            brand.setBrandName(request.getBrandName().trim());
        }

        try {
            if (request.getBrandLogo() != null && !request.getBrandLogo().isEmpty()) {
                brand.setBrandLogoUrl(cloudinaryService.uploadImage(request.getBrandLogo()));
            }
        } catch (java.io.IOException e) {
            throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
        }

        if (request.getBrandOriginCountry() != null) {
            brand.setBrandOriginCountry(request.getBrandOriginCountry().trim());
        }

        return toBrandResponse(brandRepository.save(brand));
    }

    public void deleteBrand(Long id) {
        if (!brandRepository.existsById(id)) {
            throw new AppException(ErrorCode.BRAND_NOT_EXISTED);
        }
        brandRepository.deleteById(id);
    }

    private BrandResponse toBrandResponse(Brand brand) {
        return BrandResponse.builder()
                .brandId(brand.getBrandId())
                .brandName(brand.getBrandName())
                .brandLogoUrl(brand.getBrandLogoUrl())
                .brandOriginCountry(brand.getBrandOriginCountry())
                .createdAt(brand.getCreatedAt())
                .updatedAt(brand.getUpdatedAt())
                .build();
    }
}
