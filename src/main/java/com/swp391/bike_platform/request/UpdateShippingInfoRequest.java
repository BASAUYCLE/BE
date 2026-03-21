package com.swp391.bike_platform.request;

import lombok.Data;

@Data
public class UpdateShippingInfoRequest {
    private String shippingProvider;
    private String trackingCode;
    private String shippingReceiptUrl;
}
