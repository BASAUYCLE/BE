package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.UserAddress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserAddressRepository extends JpaRepository<UserAddress, Long> {
    List<UserAddress> findByUser_UserIdOrderByIsDefaultDesc(Long userId);

    Optional<UserAddress> findByAddressIdAndUser_UserId(Long addressId, Long userId);

    Optional<UserAddress> findFirstByUser_UserId(Long userId);

    Optional<UserAddress> findFirstByUser_UserIdAndAddressIdNot(Long userId, Long addressId);

    @Modifying
    @Query("UPDATE UserAddress a SET a.isDefault = false WHERE a.user.userId = :userId")
    void clearDefaultByUserId(@Param("userId") Long userId);

    long countByUser_UserId(Long userId);
}
