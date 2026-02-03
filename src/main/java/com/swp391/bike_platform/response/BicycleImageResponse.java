package com.swp391.bike_platform.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BicycleImageResponse {
    private Long imageId;
    private Long postId;
    private String imageUrl;
    private String imageType;
    private Boolean isThumbnail;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
