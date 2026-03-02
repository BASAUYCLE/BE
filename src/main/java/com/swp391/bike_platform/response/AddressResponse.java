package com.swp391.bike_platform.response;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddressResponse {
    private Long addressId;
    private String communeCode;
    private String communeName;
    private String provinceCode;
    private String provinceName;
    private String streetAddress;
    private String fullAddress;
    private Boolean isDefault;
    private LocalDateTime createdAt;
}
