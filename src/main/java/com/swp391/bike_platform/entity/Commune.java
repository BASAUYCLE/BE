package com.swp391.bike_platform.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Communes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Commune {
    @Id
    @Column(name = "commune_code")
    private String communeCode;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "name_with_type", nullable = false)
    private String nameWithType;

    @Column(name = "type", nullable = false)
    private String type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "province_code", nullable = false)
    private Province province;
}
