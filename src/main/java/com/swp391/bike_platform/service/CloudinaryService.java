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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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

    /**
     * Add watermark to Cloudinary image via URL transformation.
     * - Logo overlay at center with 30% opacity
     * - Inspector name + inspection date as white text at bottom-right corner
     *
     * @param originalUrl    Original Cloudinary image URL
     * @param inspectorName  Name of the inspector
     * @param inspectionDate Date of inspection
     * @return Watermarked image URL
     */
    public String addWatermark(String originalUrl, String inspectorName,
            LocalDateTime inspectionDate) {
        if (originalUrl == null || !originalUrl.contains("/upload/")) {
            return originalUrl;
        }

        // Format inspection date
        String dateStr = inspectionDate.format(
                DateTimeFormatter.ofPattern("dd-MM-yyyy"));

        // Build text content: "Verified by <name> - <date>"
        String text = String.format("Verified by %s - %s", inspectorName, dateStr);
        String encodedText = URLEncoder.encode(text, StandardCharsets.UTF_8)
                .replace("+", "%20");

        // Logo overlay: center, 30% opacity, 200px width
        String logoOverlay = "l_logo_project_cv0djb,o_30,w_200,g_center";

        // Text overlay: white, 50% opacity, bottom-right, Arial 18 bold
        String textOverlay = String.format(
                "l_text:Arial_18_bold:%s,co_white,o_50,g_south_east,x_10,y_10",
                encodedText);

        String transform = logoOverlay + "/" + textOverlay;
        String watermarkedUrl = originalUrl.replace("/upload/", "/upload/" + transform + "/");

        log.info("Watermark applied to image: {}", watermarkedUrl);
        return watermarkedUrl;
    }
}
