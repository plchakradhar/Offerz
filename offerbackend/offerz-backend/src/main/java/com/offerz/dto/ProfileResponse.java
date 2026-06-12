package com.offerz.dto;

import com.offerz.entity.Address;
import java.util.List;

public class ProfileResponse {
    private String fullName;
    private String email;
    private String mobileNumber;
    private String avatarUrl;
    private List<Address> addresses;

    public ProfileResponse(String fullName, String email, String mobileNumber, String avatarUrl, List<Address> addresses) {
        this.fullName = fullName;
        this.email = email;
        this.mobileNumber = mobileNumber;
        this.avatarUrl = avatarUrl;
        this.addresses = addresses;
    }

    public String getFullName() {
        return fullName;
    }

    public String getEmail() {
        return email;
    }

    public String getMobileNumber() {
        return mobileNumber;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public List<Address> getAddresses() {
        return addresses;
    }
}
