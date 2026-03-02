package com.swp391.bike_platform.request;

import lombok.Data;

@Data
public class AddressRequest {
    private String communeCode;
    private String streetAddress;
    private Boolean isDefault;
}
