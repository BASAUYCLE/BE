package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Commune;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommuneRepository extends JpaRepository<Commune, String> {
    List<Commune> findByProvince_ProvinceCode(String provinceCode);
}
