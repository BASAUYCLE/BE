package com.swp391.bike_platform.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
@Slf4j
public class CloudinaryService {

    @Value("${cloudinary.cloud-name}")
    private String cloudName;

    @Value("${cloudinary.api-key}")
    private String apiKey;

    @Value("${cloudinary.api-secret}")
    private String apiSecret;

    private Cloudinary cloudinary;

    @PostConstruct
    public void init() {
        cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", cloudName,
                "api_key", apiKey,
                "api_secret", apiSecret,
                "secure", true));
    }

    /**
     * Upload image file to Cloudinary
     * 
     * @param imageFile MultipartFile from request
     * @return Image URL from Cloudinary
     */
    @SuppressWarnings("unchecked")
    public String uploadImage(MultipartFile imageFile) throws IOException {
        if (imageFile == null || imageFile.isEmpty()) {
            throw new IllegalArgumentException("Image file is required");
        }

        try {
            Map<String, Object> uploadResult = cloudinary.uploader().upload(
                    imageFile.getBytes(),
                    ObjectUtils.asMap(
                            "folder", "bike-platform",
                            "resource_type", "image"));

            String secureUrl = (String) uploadResult.get("secure_url");
            log.info("Image uploaded successfully to Cloudinary: {}", secureUrl);
            return secureUrl;

        } catch (Exception e) {
            log.error("Cloudinary upload error: {}", e.getMessage(), e);
            throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
        }
    }

    /**
     * Upload base64 image to Cloudinary
     * 
     * @param base64Image Base64 encoded image
     * @return Image URL from Cloudinary
     */
    @SuppressWarnings("unchecked")
    public String uploadImageFromBase64(String base64Image) {
        if (base64Image == null || base64Image.isEmpty()) {
            throw new IllegalArgumentException("Base64 image is required");
        }

        try {
            // Ensure data URI prefix
            String dataUri = base64Image;
            if (!base64Image.startsWith("data:")) {
                dataUri = "data:image/png;base64," + base64Image;
            }

            Map<String, Object> uploadResult = cloudinary.uploader().upload(
                    dataUri,
                    ObjectUtils.asMap(
                            "folder", "bike-platform",
                            "resource_type", "image"));

            String secureUrl = (String) uploadResult.get("secure_url");
            log.info("Base64 image uploaded successfully to Cloudinary: {}", secureUrl);
            return secureUrl;

        } catch (Exception e) {
            log.error("Cloudinary upload error: {}", e.getMessage(), e);
            throw new AppException(ErrorCode.IMAGE_UPLOAD_FAILED);
        }
    }

    /**
     * Delete image from Cloudinary
     * 
     * @param publicId Public ID of the image
     */
    public void deleteImage(String publicId) {
        try {
            cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
            log.info("Image deleted from Cloudinary: {}", publicId);
        } catch (Exception e) {
            log.error("Cloudinary delete error: {}", e.getMessage(), e);
        }
    }
}
