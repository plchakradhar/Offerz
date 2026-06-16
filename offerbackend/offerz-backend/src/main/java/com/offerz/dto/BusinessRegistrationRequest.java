package com.offerz.dto;

public class BusinessRegistrationRequest {
    private String mobileNumber;
    private String legalName;
    private String documentType;
    private String documentPhotoBase64;
    private String businessName;
    private String businessType;
    private String gstNumber;
    private String panNumber;
    private String yearsInBusiness;
    private String businessDoor;
    private String businessStreet;
    private String businessCity;
    private String businessState;
    private String businessPincode;
    // Pipe-separated base64 strings for shop photos
    private String shopPhotosBase64;

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
}
