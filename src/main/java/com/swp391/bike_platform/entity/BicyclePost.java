package com.swp391.bike_platform.entity;

import com.swp391.bike_platform.enums.PostStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "BicyclePosts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BicyclePost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "post_id")
    private Long postId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "seller_id", nullable = false)
    private User seller;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "brand_id", nullable = false)
    private Brand brand;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(name = "bicycle_name", nullable = false, length = 200)
    private String bicycleName;

    @Column(name = "bicycle_color", length = 50)
    private String bicycleColor;

    @Column(name = "price", nullable = false, precision = 18, scale = 2)
    private BigDecimal price;

    @Column(name = "bicycle_description", columnDefinition = "NVARCHAR(MAX)")
    private String bicycleDescription;

    @Column(name = "groupset", length = 100)
    private String groupset;

    @Column(name = "frame_material", length = 50)
    private String frameMaterial;

    @Column(name = "brake_type", length = 30)
    private String brakeType;

    @Column(name = "size", length = 200)
    private String size;

    @Column(name = "model_year")
    private Integer modelYear;

    @Column(name = "post_status", nullable = false, length = 20)
    @Builder.Default
    private String postStatus = PostStatus.PENDING.name();

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<BicycleImage> images = new ArrayList<>();
}
