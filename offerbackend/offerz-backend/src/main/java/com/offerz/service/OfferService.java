package com.offerz.service;

import com.offerz.entity.Offer;
import com.offerz.repository.OfferRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OfferService {

    @Autowired
    private OfferRepository offerRepository;

    public Offer saveOffer(Offer offer) {
        return offerRepository.save(offer);
    }

    public List<Offer> getOffersByBusinessMobile(String mobile) {
        return offerRepository.findByBusinessMobileNumberOrderByCreatedAtDesc(mobile);
    }

    public List<Offer> getOffersByCity(String city) {
        if (city == null || city.trim().isEmpty() || city.equalsIgnoreCase("all")) {
            return offerRepository.findAllByOrderByCreatedAtDesc();
        }
        return offerRepository.findByCityIgnoreCaseOrderByCreatedAtDesc(city);
    }

    public List<Offer> getAllOffers() {
        return offerRepository.findAllByOrderByCreatedAtDesc();
    }

    public void deleteOffer(Long id) {
        offerRepository.deleteById(id);
    }

    public Offer getOfferById(Long id) {
        return offerRepository.findById(id).orElse(null);
    }
}
