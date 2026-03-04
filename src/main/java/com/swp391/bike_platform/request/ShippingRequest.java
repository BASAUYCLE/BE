package com.swp391.bike_platform.request;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShippingRequest {
    private String shippingMethod;
    private String shippingTrackingNumber;
}
