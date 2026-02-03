package com.swp391.bike_platform.request;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class BicyclePostUpdateRequest {
    private Long brandId;
    private Long categoryId;
    private String bicycleName;
    private String bicycleColor;
    private BigDecimal price;
    private String bicycleDescription;
    private String groupset;
    private String frameMaterial;
    private String brakeType;
    private String size;
    private Integer modelYear;
}
