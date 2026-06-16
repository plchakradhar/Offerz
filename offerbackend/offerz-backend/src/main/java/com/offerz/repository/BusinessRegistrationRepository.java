package com.offerz.repository;

import com.offerz.entity.BusinessRegistration;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface BusinessRegistrationRepository extends JpaRepository<BusinessRegistration, Long> {
    Optional<BusinessRegistration> findByMobileNumber(String mobileNumber);
    List<BusinessRegistration> findByStatus(BusinessRegistration.Status status);
    boolean existsByMobileNumber(String mobileNumber);
}
