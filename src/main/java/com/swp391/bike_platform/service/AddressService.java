package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.Commune;
import com.swp391.bike_platform.entity.User;
import com.swp391.bike_platform.entity.UserAddress;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.CommuneRepository;
import com.swp391.bike_platform.repository.OrderRepository;
import com.swp391.bike_platform.repository.UserAddressRepository;
import com.swp391.bike_platform.request.AddressRequest;
import com.swp391.bike_platform.response.AddressResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AddressService {

    private final UserAddressRepository addressRepository;
    private final CommuneRepository communeRepository;
    private final OrderRepository orderRepository;
    private final UserService userService;

    /**
     * Get all addresses of a user
     */
    public List<AddressResponse> getUserAddresses(Long userId) {
        return addressRepository.findByUser_UserIdOrderByIsDefaultDesc(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get a specific address by id (must belong to user)
     */
    public AddressResponse getAddressById(Long userId, Long addressId) {
        UserAddress address = addressRepository.findByAddressIdAndUser_UserId(addressId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.ADDRESS_NOT_FOUND));
        return toResponse(address);
    }

    /**
     * Create a new address
     */
    @Transactional
    public AddressResponse createAddress(Long userId, AddressRequest request) {
        User user = userService.getUserEntityById(userId);
        Commune commune = communeRepository.findById(request.getCommuneCode())
                .orElseThrow(() -> new AppException(ErrorCode.COMMUNE_NOT_FOUND));

        // Build full address: street + commune + province
        String fullAddress = buildFullAddress(request.getStreetAddress(), commune);

        // If this is the first address or isDefault=true, clear other defaults
        boolean isFirst = addressRepository.countByUser_UserId(userId) == 0;
        boolean setDefault = isFirst || Boolean.TRUE.equals(request.getIsDefault());

        if (setDefault) {
            addressRepository.clearDefaultByUserId(userId);
        }

        UserAddress address = UserAddress.builder()
                .user(user)
                .commune(commune)
                .streetAddress(request.getStreetAddress())
                .fullAddress(fullAddress)
                .isDefault(setDefault)
                .build();

        return toResponse(addressRepository.save(address));
    }

    /**
     * Update an existing address
     */
    @Transactional
    public AddressResponse updateAddress(Long userId, Long addressId, AddressRequest request) {
        UserAddress address = addressRepository.findByAddressIdAndUser_UserId(addressId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.ADDRESS_NOT_FOUND));

        if (request.getCommuneCode() != null) {
            Commune commune = communeRepository.findById(request.getCommuneCode())
                    .orElseThrow(() -> new AppException(ErrorCode.COMMUNE_NOT_FOUND));
            address.setCommune(commune);
        }

        if (request.getStreetAddress() != null) {
            address.setStreetAddress(request.getStreetAddress());
        }

        // Rebuild full address
        address.setFullAddress(buildFullAddress(address.getStreetAddress(), address.getCommune()));

        // Handle default flag
        if (Boolean.TRUE.equals(request.getIsDefault())) {
            addressRepository.clearDefaultByUserId(userId);
            address.setIsDefault(true);
        }

        return toResponse(addressRepository.save(address));
    }

    /**
     * Delete an address
     */
    @Transactional
    public void deleteAddress(Long userId, Long addressId) {
        UserAddress address = addressRepository.findByAddressIdAndUser_UserId(addressId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.ADDRESS_NOT_FOUND));

        // Check if address is being used in any order
        if (orderRepository.existsByAddress_AddressId(addressId)) {
            throw new AppException(ErrorCode.ADDRESS_IN_USE);
        }

        boolean wasDefault = Boolean.TRUE.equals(address.getIsDefault());
        addressRepository.delete(address);

        // If deleted address was default, set another one as default
        if (wasDefault) {
            addressRepository.findFirstByUser_UserIdAndAddressIdNot(userId, addressId)
                    .ifPresent(a -> {
                        a.setIsDefault(true);
                        addressRepository.save(a);
                    });
        }
    }

    private String buildFullAddress(String street, Commune commune) {
        StringBuilder sb = new StringBuilder();
        if (street != null && !street.isBlank()) {
            sb.append(street).append(", ");
        }
        sb.append(commune.getNameWithType());
        sb.append(", ").append(commune.getProvince().getNameWithType());
        return sb.toString();
    }

    private AddressResponse toResponse(UserAddress a) {
        return AddressResponse.builder()
                .addressId(a.getAddressId())
                .communeCode(a.getCommune().getCommuneCode())
                .communeName(a.getCommune().getNameWithType())
                .provinceCode(a.getCommune().getProvince().getProvinceCode())
                .provinceName(a.getCommune().getProvince().getNameWithType())
                .streetAddress(a.getStreetAddress())
                .fullAddress(a.getFullAddress())
                .isDefault(a.getIsDefault())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
