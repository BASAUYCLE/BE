package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.request.BicycleImageCreateRequest;
import com.swp391.bike_platform.request.BicycleImageUpdateRequest;
import com.swp391.bike_platform.response.BicycleImageResponse;
import com.swp391.bike_platform.service.BicycleImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/images")
@RequiredArgsConstructor
public class BicycleImageController {

    private final BicycleImageService bicycleImageService;

    @PostMapping
    public BicycleImageResponse createImage(@ModelAttribute BicycleImageCreateRequest request) {
        return bicycleImageService.createImage(request);
    }

    @GetMapping("/post/{postId}")
    public List<BicycleImageResponse> getImagesByPostId(@PathVariable Long postId) {
        return bicycleImageService.getImagesByPostId(postId);
    }

    @GetMapping("/{imageId}")
    public BicycleImageResponse getImageById(@PathVariable Long imageId) {
        return bicycleImageService.getImageById(imageId);
    }

    @PutMapping("/{imageId}")
    public BicycleImageResponse updateImage(@PathVariable Long imageId,
            @ModelAttribute BicycleImageUpdateRequest request) {
        return bicycleImageService.updateImage(imageId, request);
    }

    @DeleteMapping("/{imageId}")
    public String deleteImage(@PathVariable Long imageId) {
        bicycleImageService.deleteImage(imageId);
        return "Bicycle image has been deleted";
    }
}
