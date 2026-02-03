package com.swp391.bike_platform.request;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class BicycleImageUpdateRequest {
    private MultipartFile image;
    private String imageType;
    private Boolean isThumbnail;
}
