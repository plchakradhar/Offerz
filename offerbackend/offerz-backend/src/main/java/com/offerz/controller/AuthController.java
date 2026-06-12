package com.offerz.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.offerz.dto.OtpRequest;
import com.offerz.dto.SignupRequest;
import com.offerz.dto.VerifyResponse;
import com.offerz.service.AuthService;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody SignupRequest request) {
        try {
            String otp = authService.signup(request);
            return ResponseEntity.ok("OTP: " + otp);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/verify-signup")
    public ResponseEntity<?> verifySignup(@RequestBody OtpRequest request) {
        boolean verified = authService.verifyOtp(request.getMobileNumber(), request.getOtp());
        if (verified) {
            return ResponseEntity.ok(new VerifyResponse("success", null));
        } else {
            return ResponseEntity.badRequest().body("Invalid OTP");
        }
    }

    @PostMapping("/login/getotp")
    public ResponseEntity<String> loginOtp(@RequestParam String mobile) {
        if (!authService.checkMobileExists(mobile)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("Mobile number not registered. Please sign up.");
        }
        String otp = authService.generateOtp(mobile);
        return ResponseEntity.ok("OTP: " + otp);
    }

    @PostMapping("/login/verify")
    public ResponseEntity<?> loginVerify(@RequestBody OtpRequest request) {
        boolean verified = authService.verifyOtp(request.getMobileNumber(), request.getOtp());
        if (verified) {
            String fullName = authService.getFullNameByMobile(request.getMobileNumber());
            return ResponseEntity.ok(new VerifyResponse("success", fullName));
        } else {
            return ResponseEntity.badRequest().body("Invalid OTP");
        }
    }
}