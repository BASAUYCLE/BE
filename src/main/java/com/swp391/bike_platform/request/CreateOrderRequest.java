package com.swp391.bike_platform.request;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {
    private Long postId;
    private Long addressId;
    private boolean payFull;
}
