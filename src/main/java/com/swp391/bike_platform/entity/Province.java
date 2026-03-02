package com.swp391.bike_platform.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Provinces")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Province {
    @Id
    @Column(name = "province_code")
    private String provinceCode;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "name_with_type", nullable = false)
    private String nameWithType;

    @Column(name = "type", nullable = false)
    private String type;
}
