package com.offerz.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "business_registrations")
public class BusinessRegistration {

    public enum Status { PENDING, VERIFIED, REJECTED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String mobileNumber;

    // Personal / KYC
    private String legalName;
    private String documentType;   // "AADHAAR" or "PAN"

    @Column(columnDefinition = "LONGTEXT")
    private String documentPhotoBase64;   // Base64-encoded KYC document photo

    // Business Info
    private String businessName;
    private String businessType;   // Retail / Food & Beverage / Service / Healthcare / Other
    private String gstNumber;
    private String panNumber;
    private String yearsInBusiness;

    // Business Address
    private String businessDoor;
    private String businessStreet;
    private String businessCity;
    private String businessState;
    private String businessPincode;

    // Shop Photos (base64, pipe-separated — up to 10)
    @Column(columnDefinition = "LONGTEXT")
    private String shopPhotosBase64;

    // Subscription
    private String subscriptionPlan = "BASIC"; // BASIC, PREMIUM, DIAMOND

    // Status
    @Enumerated(EnumType.STRING)
    private Status status = Status.PENDING;

    @Column(length = 1000)
    private String adminRemark;

    private LocalDateTime submittedAt;
    private LocalDateTime updatedAt;

    // ── Constructors ──────────────────────────────────────────────────────────

    public BusinessRegistration() {}

    @PrePersist
    public void prePersist() {
        this.submittedAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Long getId() { return id; }

    public String getMobileNumber() { return mobileNumber; }
    public void setMobileNumber(String mobileNumber) { this.mobileNumber = mobileNumber; }

    public String getLegalName() { return legalName; }
    public void setLegalName(String legalName) { this.legalName = legalName; }

    public String getDocumentType() { return documentType; }
    public void setDocumentType(String documentType) { this.documentType = documentType; }

    public String getDocumentPhotoBase64() { return documentPhotoBase64; }
    public void setDocumentPhotoBase64(String documentPhotoBase64) { this.documentPhotoBase64 = documentPhotoBase64; }

    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) { this.businessName = businessName; }

    public String getBusinessType() { return businessType; }
    public void setBusinessType(String businessType) { this.businessType = businessType; }

    public String getGstNumber() { return gstNumber; }
    public void setGstNumber(String gstNumber) { this.gstNumber = gstNumber; }

    public String getPanNumber() { return panNumber; }
    public void setPanNumber(String panNumber) { this.panNumber = panNumber; }

    public String getYearsInBusiness() { return yearsInBusiness; }
    public void setYearsInBusiness(String yearsInBusiness) { this.yearsInBusiness = yearsInBusiness; }

    public String getBusinessDoor() { return businessDoor; }
    public void setBusinessDoor(String businessDoor) { this.businessDoor = businessDoor; }

    public String getBusinessStreet() { return businessStreet; }
    public void setBusinessStreet(String businessStreet) { this.businessStreet = businessStreet; }

    public String getBusinessCity() { return businessCity; }
    public void setBusinessCity(String businessCity) { this.businessCity = businessCity; }

    public String getBusinessState() { return businessState; }
    public void setBusinessState(String businessState) { this.businessState = businessState; }

    public String getBusinessPincode() { return businessPincode; }
    public void setBusinessPincode(String businessPincode) { this.businessPincode = businessPincode; }

    public String getShopPhotosBase64() { return shopPhotosBase64; }
    public void setShopPhotosBase64(String shopPhotosBase64) { this.shopPhotosBase64 = shopPhotosBase64; }

    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }

    public String getAdminRemark() { return adminRemark; }
    public void setAdminRemark(String adminRemark) { this.adminRemark = adminRemark; }

    public LocalDateTime getSubmittedAt() { return submittedAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    public String getSubscriptionPlan() { return subscriptionPlan; }
    public void setSubscriptionPlan(String subscriptionPlan) { this.subscriptionPlan = subscriptionPlan; }
}
