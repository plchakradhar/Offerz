package com.offerz.repository;

import com.offerz.entity.Offer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OfferRepository extends JpaRepository<Offer, Long> {
    List<Offer> findByBusinessMobileNumberOrderByCreatedAtDesc(String businessMobileNumber);
    List<Offer> findByCityIgnoreCaseOrderByCreatedAtDesc(String city);
    List<Offer> findAllByOrderByCreatedAtDesc();
}
