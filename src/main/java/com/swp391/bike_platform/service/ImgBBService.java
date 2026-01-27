package com.swp391.bike_platform.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.Map;

@Service
@Slf4j
public class ImgBBService {

    @Value("${imgbb.api-key}")
    private String apiKey;

    @Value("${imgbb.api-url}")
    private String apiUrl;

    @Value("${imgbb.expiration}")
    private Integer expiration;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Upload image file to ImgBB
     * 
     * @param imageFile MultipartFile from request
     * @return Image URL from ImgBB
     */
    public String uploadImage(MultipartFile imageFile) throws IOException {
        if (imageFile == null || imageFile.isEmpty()) {
            throw new IllegalArgumentException("Image file is required");
        }

        // Convert to Base64
        byte[] imageBytes = imageFile.getBytes();
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);

        return uploadToImgBB(base64Image, imageFile.getOriginalFilename());
    }

    /**
     * Upload base64 image to ImgBB
     * 
     * @param base64Image Base64 encoded image
     * @return Image URL from ImgBB
     */
    public String uploadImageFromBase64(String base64Image) {
        if (base64Image == null || base64Image.isEmpty()) {
            throw new IllegalArgumentException("Base64 image is required");
        }

        // Remove data URI prefix if present (e.g., "data:image/png;base64,")
        if (base64Image.contains(",")) {
            base64Image = base64Image.split(",")[1];
        }

        return uploadToImgBB(base64Image, null);
    }

    /**
     * Internal method to upload to ImgBB API
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    private String uploadToImgBB(String base64Image, String filename) {
        // Prepare request headers
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        // Prepare request body
        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("key", apiKey);
        body.add("image", base64Image);

        if (filename != null && !filename.isEmpty()) {
            body.add("name", filename);
        }

        if (expiration != null && expiration > 0) {
            body.add("expiration", String.valueOf(expiration));
        }

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);

        try {
            // Call ImgBB API
            ResponseEntity<Map> response = restTemplate.postForEntity(
                    apiUrl,
                    request,
                    Map.class);

            // Extract image URL from response
            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();
                Map<String, Object> data = (Map<String, Object>) responseBody.get("data");

                if (data != null) {
                    String displayUrl = (String) data.get("display_url");
                    String url = (String) data.get("url");

                    log.info("Image uploaded successfully to ImgBB: {}", displayUrl);
                    return displayUrl != null ? displayUrl : url;
                }
            }

            log.error("ImgBB upload failed: Invalid response from API");
            throw new RuntimeException("Failed to upload image to ImgBB");

        } catch (Exception e) {
            log.error("ImgBB upload error: {}", e.getMessage(), e);
            throw new RuntimeException("Image upload failed: " + e.getMessage());
        }
    }
}
