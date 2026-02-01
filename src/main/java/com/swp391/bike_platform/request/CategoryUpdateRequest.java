package com.swp391.bike_platform.request;

import lombok.Data;

@Data
public class CategoryUpdateRequest {
    private String categoryName;
    private String categoryDescription;
}
