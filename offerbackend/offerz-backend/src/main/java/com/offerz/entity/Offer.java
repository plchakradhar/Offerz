package com.offerz.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "offers")
public class Offer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String businessMobileNumber;

    private String shopName;

    @Column(length = 2000)
    private String description;

    private Double originalPrice;
    private Double discountPrice;

    private String exactLocationAddress;
    private String city;

    private LocalDate fromDate;
    private LocalDate toDate;

    private String openingTime;
    private String closingTime;

    private String category;

    @Column(columnDefinition = "LONGTEXT")
    private String photosBase64; // Pipe-separated base64 images

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Offer() {}

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }

    public String getBusinessMobileNumber() { return businessMobileNumber; }
    public void setBusinessMobileNumber(String businessMobileNumber) { this.businessMobileNumber = businessMobileNumber; }

    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Double getOriginalPrice() { return originalPrice; }
    public void setOriginalPrice(Double originalPrice) { this.originalPrice = originalPrice; }

    public Double getDiscountPrice() { return discountPrice; }
    public void setDiscountPrice(Double discountPrice) { this.discountPrice = discountPrice; }

    public String getExactLocationAddress() { return exactLocationAddress; }
    public void setExactLocationAddress(String exactLocationAddress) { this.exactLocationAddress = exactLocationAddress; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public LocalDate getFromDate() { return fromDate; }
    public void setFromDate(LocalDate fromDate) { this.fromDate = fromDate; }

    public LocalDate getToDate() { return toDate; }
    public void setToDate(LocalDate toDate) { this.toDate = toDate; }

    public String getOpeningTime() { return openingTime; }
    public void setOpeningTime(String openingTime) { this.openingTime = openingTime; }

    public String getClosingTime() { return closingTime; }
    public void setClosingTime(String closingTime) { this.closingTime = closingTime; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getPhotosBase64() { return photosBase64; }
    public void setPhotosBase64(String photosBase64) { this.photosBase64 = photosBase64; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
