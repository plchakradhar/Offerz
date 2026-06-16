package com.offerz.controller;

import com.offerz.entity.Offer;
import com.offerz.service.OfferService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/offers")
@CrossOrigin(origins = "*")
public class OfferController {

    @Autowired
    private OfferService offerService;

    @PostMapping
    public ResponseEntity<Offer> createOffer(@RequestBody Offer offer) {
        Offer savedOffer = offerService.saveOffer(offer);
        return ResponseEntity.ok(savedOffer);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Offer> updateOffer(@PathVariable Long id, @RequestBody Offer offerDetails) {
        Offer offer = offerService.getOfferById(id);
        if (offer == null) {
            return ResponseEntity.notFound().build();
        }
        
        offer.setShopName(offerDetails.getShopName());
        offer.setDescription(offerDetails.getDescription());
        offer.setOriginalPrice(offerDetails.getOriginalPrice());
        offer.setDiscountPrice(offerDetails.getDiscountPrice());
        offer.setExactLocationAddress(offerDetails.getExactLocationAddress());
        offer.setCity(offerDetails.getCity());
        offer.setFromDate(offerDetails.getFromDate());
        offer.setToDate(offerDetails.getToDate());
        offer.setOpeningTime(offerDetails.getOpeningTime());
        offer.setClosingTime(offerDetails.getClosingTime());
        offer.setCategory(offerDetails.getCategory());
        offer.setPhotosBase64(offerDetails.getPhotosBase64());
        
        Offer updatedOffer = offerService.saveOffer(offer);
        return ResponseEntity.ok(updatedOffer);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOffer(@PathVariable Long id) {
        Offer offer = offerService.getOfferById(id);
        if (offer == null) {
            return ResponseEntity.notFound().build();
        }
        offerService.deleteOffer(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/business/{mobile}")
    public ResponseEntity<List<Offer>> getOffersByBusiness(@PathVariable String mobile) {
        List<Offer> offers = offerService.getOffersByBusinessMobile(mobile);
        return ResponseEntity.ok(offers);
    }

    @GetMapping("/location/{city}")
    public ResponseEntity<List<Offer>> getOffersByLocation(@PathVariable String city) {
        List<Offer> offers = offerService.getOffersByCity(city);
        return ResponseEntity.ok(offers);
    }

    // Admin: get all offers across all businesses
    @GetMapping
    public ResponseEntity<List<Offer>> getAllOffers() {
        List<Offer> offers = offerService.getAllOffers();
        return ResponseEntity.ok(offers);
    }
}
