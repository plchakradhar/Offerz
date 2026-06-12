package com.offerz.repository;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import com.offerz.entity.User;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByMobileNumber(String mobileNumber);
    boolean existsByMobileNumber(String mobileNumber);
    boolean existsByEmail(String email);
}