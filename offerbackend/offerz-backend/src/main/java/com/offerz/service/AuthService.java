package com.offerz.service;

import java.util.Random;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.offerz.dto.SignupRequest;
import com.offerz.entity.User;
import com.offerz.repository.UserRepository;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    public boolean checkMobileExists(String mobileNumber) {
        return userRepository.existsByMobileNumber(mobileNumber);
    }

    public String getFullNameByMobile(String mobileNumber) {
        return userRepository.findByMobileNumber(mobileNumber)
                .map(User::getFullName)
                .orElse(null);
    }

    /**
     * Generates a 4-digit OTP and PERSISTS it in the database.
     * This ensures OTPs survive server restarts — no more "Failed to connect" issues.
     */
    public String generateOtp(String mobileNumber) {
        String otp = String.format("%04d", new Random().nextInt(10000));
        userRepository.findByMobileNumber(mobileNumber).ifPresent(user -> {
            user.setOtp(otp);
            userRepository.save(user);
        });
        return otp;
    }

    public String signup(SignupRequest request) {
        if (userRepository.existsByMobileNumber(request.getMobileNumber())) {
            throw new RuntimeException("Mobile number already registered");
        }
        if (request.getEmail() != null && !request.getEmail().isBlank()
                && userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        User user = new User();
        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setMobileNumber(request.getMobileNumber());
        user.setVerified(false);

        userRepository.save(user);
        return generateOtp(request.getMobileNumber());
    }

    /**
     * Verifies OTP from database instead of in-memory map.
     */
    public boolean verifyOtp(String mobile, String otp) {
        User user = userRepository.findByMobileNumber(mobile).orElse(null);
        if (user != null && otp != null && otp.equals(user.getOtp())) {
            user.setVerified(true);
            user.setOtp(null); // Clear OTP after use for security
            userRepository.save(user);
            return true;
        }
        return false;
    }
}