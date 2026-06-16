package com.offerz.controller;

import com.offerz.dto.BusinessActionRequest;
import com.offerz.dto.BusinessRegistrationRequest;
import com.offerz.entity.BusinessRegistration;
import com.offerz.entity.User;
import com.offerz.repository.BusinessRegistrationRepository;
import com.offerz.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/business")
@CrossOrigin(origins = "*")
public class BusinessController {

    @Autowired
    private BusinessRegistrationRepository businessRepo;

    @Autowired
    private UserRepository userRepository;

    // ── USER ENDPOINTS ────────────────────────────────────────────────────────

    /**
     * Submit a new business registration.
     * If one already exists for this mobile, it is rejected and replaced (re-submission).
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody BusinessRegistrationRequest req) {
        // Remove old (rejected) registration if re-submitting
        businessRepo.findByMobileNumber(req.getMobileNumber()).ifPresent(existing -> {
            if (existing.getStatus() == BusinessRegistration.Status.REJECTED) {
                businessRepo.delete(existing);
            }
        });

        // Don't allow double-submission if pending or verified
        if (businessRepo.existsByMobileNumber(req.getMobileNumber())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("status", "error", "message", "A registration is already in progress"));
        }

        BusinessRegistration reg = new BusinessRegistration();
        reg.setMobileNumber(req.getMobileNumber());
        reg.setLegalName(req.getLegalName());
        reg.setDocumentType(req.getDocumentType());
        reg.setDocumentPhotoBase64(req.getDocumentPhotoBase64());
        reg.setBusinessName(req.getBusinessName());
        reg.setBusinessType(req.getBusinessType());
        reg.setGstNumber(req.getGstNumber());
        reg.setPanNumber(req.getPanNumber());
        reg.setYearsInBusiness(req.getYearsInBusiness());
        reg.setBusinessDoor(req.getBusinessDoor());
        reg.setBusinessStreet(req.getBusinessStreet());
        reg.setBusinessCity(req.getBusinessCity());
        reg.setBusinessState(req.getBusinessState());
        reg.setBusinessPincode(req.getBusinessPincode());
        reg.setShopPhotosBase64(req.getShopPhotosBase64());
        reg.setStatus(BusinessRegistration.Status.PENDING);

        businessRepo.save(reg);
        return ResponseEntity.ok(Map.of("status", "success", "message", "Registration submitted successfully"));
    }

    /**
     * Get current user's registration status.
     */
    @GetMapping("/status")
    public ResponseEntity<?> getStatus(@RequestParam String mobile) {
        Optional<BusinessRegistration> opt = businessRepo.findByMobileNumber(mobile);
        if (opt.isEmpty()) {
            return ResponseEntity.ok(Map.of("status", "NOT_SUBMITTED"));
        }
        BusinessRegistration reg = opt.get();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", reg.getStatus().name());
        result.put("businessName", reg.getBusinessName());
        result.put("subscriptionPlan", reg.getSubscriptionPlan());
        result.put("submittedAt", reg.getSubmittedAt() != null ? reg.getSubmittedAt().toString() : null);
        result.put("adminRemark", reg.getAdminRemark());
        return ResponseEntity.ok(result);
    }

    /**
     * Update business subscription plan.
     */
    @PutMapping("/subscription")
    public ResponseEntity<?> updateSubscription(@RequestParam String mobile, @RequestBody Map<String, String> body) {
        Optional<BusinessRegistration> opt = businessRepo.findByMobileNumber(mobile);
        if (opt.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("status", "error", "message", "Business not found"));
        }
        BusinessRegistration reg = opt.get();
        String plan = body.get("plan");
        if (plan != null) {
            reg.setSubscriptionPlan(plan.toUpperCase());
            businessRepo.save(reg);
            return ResponseEntity.ok(Map.of("status", "success", "message", "Subscription updated", "plan", plan.toUpperCase()));
        }
        return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Plan not provided"));
    }

    // ── ADMIN ENDPOINTS ───────────────────────────────────────────────────────

    /**
     * Admin login — hardcoded credentials.
     */
    @PostMapping("/admin/login")
    public ResponseEntity<?> adminLogin(@RequestBody Map<String, String> body) {
        String phone = body.get("phone");
        String otp = body.get("otp");
        if ("7953161920".equals(phone) && "2006".equals(otp)) {
            return ResponseEntity.ok(Map.of("status", "success", "token", "ADMIN_TOKEN_2006"));
        }
        return ResponseEntity.status(401).body(Map.of("status", "error", "message", "Invalid credentials"));
    }

    /**
     * Get all users (admin).
     */
    @GetMapping("/admin/users")
    public ResponseEntity<?> getAllUsers(@RequestHeader(value = "X-Admin-Token", required = false) String token) {
        if (!"ADMIN_TOKEN_2006".equals(token)) {
            return ResponseEntity.status(403).body(Map.of("status", "error", "message", "Unauthorized"));
        }
        List<User> users = userRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();
        for (User u : users) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", u.getId());
            m.put("fullName", u.getFullName());
            m.put("mobileNumber", u.getMobileNumber());
            m.put("email", u.getEmail());
            m.put("avatarUrl", u.getAvatarUrl());
            m.put("verified", u.isVerified());
            result.add(m);
        }
        return ResponseEntity.ok(result);
    }

    /**
     * Get all business registrations (admin).
     */
    @GetMapping("/admin/requests")
    public ResponseEntity<?> getAllRequests(@RequestHeader(value = "X-Admin-Token", required = false) String token) {
        if (!"ADMIN_TOKEN_2006".equals(token)) {
            return ResponseEntity.status(403).body(Map.of("status", "error", "message", "Unauthorized"));
        }
        List<BusinessRegistration> regs = businessRepo.findAll();
        List<Map<String, Object>> result = new ArrayList<>();
        for (BusinessRegistration r : regs) {
            result.add(toMap(r));
        }
        return ResponseEntity.ok(result);
    }

    /**
     * Admin action: approve or reject a business request.
     */
    @PutMapping("/admin/action/{id}")
    public ResponseEntity<?> actionRequest(
            @PathVariable Long id,
            @RequestHeader(value = "X-Admin-Token", required = false) String token,
            @RequestBody BusinessActionRequest req) {
        if (!"ADMIN_TOKEN_2006".equals(token)) {
            return ResponseEntity.status(403).body(Map.of("status", "error", "message", "Unauthorized"));
        }
        Optional<BusinessRegistration> opt = businessRepo.findById(id);
        if (opt.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("status", "error", "message", "Request not found"));
        }
        BusinessRegistration reg = opt.get();
        try {
            BusinessRegistration.Status newStatus = BusinessRegistration.Status.valueOf(req.getStatus());
            reg.setStatus(newStatus);
            reg.setAdminRemark(req.getRemark());
            businessRepo.save(reg);

            // If verified — update user's businessVerified flag
            // (We reflect status back through the /api/business/status endpoint,
            //  no extra column needed on User for now)
            return ResponseEntity.ok(Map.of("status", "success",
                    "message", "Request " + newStatus.name().toLowerCase() + " successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Invalid status value"));
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Map<String, Object> toMap(BusinessRegistration r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("mobileNumber", r.getMobileNumber());
        m.put("legalName", r.getLegalName());
        m.put("documentType", r.getDocumentType());
        m.put("documentPhotoBase64", r.getDocumentPhotoBase64());
        m.put("businessName", r.getBusinessName());
        m.put("businessType", r.getBusinessType());
        m.put("gstNumber", r.getGstNumber());
        m.put("panNumber", r.getPanNumber());
        m.put("yearsInBusiness", r.getYearsInBusiness());
        m.put("businessDoor", r.getBusinessDoor());
        m.put("businessStreet", r.getBusinessStreet());
        m.put("businessCity", r.getBusinessCity());
        m.put("businessState", r.getBusinessState());
        m.put("businessPincode", r.getBusinessPincode());
        m.put("shopPhotosBase64", r.getShopPhotosBase64());
        m.put("subscriptionPlan", r.getSubscriptionPlan());
        m.put("status", r.getStatus().name());
        m.put("adminRemark", r.getAdminRemark());
        m.put("submittedAt", r.getSubmittedAt() != null ? r.getSubmittedAt().toString() : null);
        m.put("updatedAt", r.getUpdatedAt() != null ? r.getUpdatedAt().toString() : null);
        return m;
    }
}
