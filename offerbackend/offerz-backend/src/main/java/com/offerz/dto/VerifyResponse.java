package com.offerz.dto;

public class VerifyResponse {
    private String status;
    private String fullName;

    public VerifyResponse(String status, String fullName) {
        this.status = status;
        this.fullName = fullName;
    }

    public String getStatus() { return status; }
    public String getFullName() { return fullName; }
}