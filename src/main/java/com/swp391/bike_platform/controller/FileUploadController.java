package com.swp391.bike_platform.controller;

import com.swp391.bike_platform.service.ImgBBService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
public class FileUploadController {

    private final ImgBBService imgBBService;

    /**
     * Upload image to ImgBB
     * POST /api/upload/image
     * 
     * @param file Image file (multipart/form-data)
     * @return JSON response with imageUrl
     */
    @PostMapping("/image")
    public ResponseEntity<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            // Validate file
            if (file.isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("success", "false");
                error.put("error", "File is empty");
                return ResponseEntity.badRequest().body(error);
            }

            // Validate file type
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                Map<String, String> error = new HashMap<>();
                error.put("success", "false");
                error.put("error", "File must be an image");
                return ResponseEntity.badRequest().body(error);
            }

            // Upload to ImgBB
            String imageUrl = imgBBService.uploadImage(file);

            // Return success response
            Map<String, String> response = new HashMap<>();
            response.put("success", "true");
            response.put("imageUrl", imageUrl);
            response.put("message", "Image uploaded successfully");

            return ResponseEntity.ok(response);

        } catch (IOException e) {
            Map<String, String> error = new HashMap<>();
            error.put("success", "false");
            error.put("error", "Failed to read image file: " + e.getMessage());
            return ResponseEntity.badRequest().body(error);

        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("success", "false");
            error.put("error", e.getMessage());
            return ResponseEntity.internalServerError().body(error);
        }
    }
}
