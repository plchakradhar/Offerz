package com.offerz.dto;

public class BusinessActionRequest {
    private String status;   // "VERIFIED" or "REJECTED"
    private String remark;

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
}
