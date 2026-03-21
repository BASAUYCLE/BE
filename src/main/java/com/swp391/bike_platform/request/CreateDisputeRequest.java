package com.swp391.bike_platform.request;

import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class CreateDisputeRequest {
    private Long orderId;
    private String reason;
    private MultipartFile proofImage;
}
