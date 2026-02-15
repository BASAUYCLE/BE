package com.swp391.bike_platform.repository;

import com.swp391.bike_platform.entity.Wishlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WishlistRepository extends JpaRepository<Wishlist, Long> {

    List<Wishlist> findByUser_UserId(Long userId);

    Optional<Wishlist> findByUser_UserIdAndPost_PostId(Long userId, Long postId);

    boolean existsByUser_UserIdAndPost_PostId(Long userId, Long postId);

    void deleteByUser_UserIdAndPost_PostId(Long userId, Long postId);
}
