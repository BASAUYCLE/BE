package com.swp391.bike_platform.entity;

import com.swp391.bike_platform.enums.DisputeStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "Disputes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Dispute {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dispute_id")
    private Long disputeId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id", nullable = false)
    private User buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inspector_id")
    private User inspector;

    @Column(name = "status", nullable = false, length = 50)
    @Builder.Default
    private String status = DisputeStatus.OPEN.name();

    @Column(name = "reason", nullable = false, columnDefinition = "NVARCHAR(500)")
    private String reason;

    @Column(name = "proof_images", nullable = false, length = 1000)
    private String proofImages;

    @Column(name = "inspector_note", columnDefinition = "NVARCHAR(1000)")
    private String inspectorNote;

    @Column(name = "admin_note", columnDefinition = "NVARCHAR(1000)")
    private String adminNote;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by")
    private User resolvedBy;

    @Column(name = "shipping_provider", columnDefinition = "NVARCHAR(100)")
    private String shippingProvider;

    @Column(name = "tracking_code", length = 200)
    private String trackingCode;

    @Column(name = "shipping_receipt_url", length = 500)
    private String shippingReceiptUrl;

    @Column(name = "return_shipped_at")
    private LocalDateTime returnShippedAt;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
