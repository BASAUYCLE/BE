package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.Commune;
import com.swp391.bike_platform.entity.Province;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.CommuneRepository;
import com.swp391.bike_platform.repository.ProvinceRepository;
import com.swp391.bike_platform.response.CommuneResponse;
import com.swp391.bike_platform.response.ProvinceResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LocationService {

    private final ProvinceRepository provinceRepository;
    private final CommuneRepository communeRepository;

    /**
     * Get all provinces
     */
    public List<ProvinceResponse> getAllProvinces() {
        return provinceRepository.findAll().stream()
                .map(this::toProvinceResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get communes by province code
     */
    public List<CommuneResponse> getCommunesByProvince(String provinceCode) {
        // Check province exists
        if (!provinceRepository.existsById(provinceCode)) {
            throw new AppException(ErrorCode.PROVINCE_NOT_FOUND);
        }
        return communeRepository.findByProvince_ProvinceCode(provinceCode).stream()
                .map(this::toCommuneResponse)
                .collect(Collectors.toList());
    }

    private ProvinceResponse toProvinceResponse(Province p) {
        return ProvinceResponse.builder()
                .provinceCode(p.getProvinceCode())
                .name(p.getName())
                .nameWithType(p.getNameWithType())
                .build();
    }

    private CommuneResponse toCommuneResponse(Commune c) {
        return CommuneResponse.builder()
                .communeCode(c.getCommuneCode())
                .name(c.getName())
                .nameWithType(c.getNameWithType())
                .build();
    }
}
