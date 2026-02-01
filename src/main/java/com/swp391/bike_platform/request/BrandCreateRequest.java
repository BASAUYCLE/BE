package com.swp391.bike_platform.request;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class BrandCreateRequest {
    private String brandName;
    private MultipartFile brandLogo;
    private String brandOriginCountry;
}
