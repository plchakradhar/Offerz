package com.offerz.controller;

import com.offerz.dto.AddressRequest;
import com.offerz.dto.ProfileResponse;
import com.offerz.dto.ProfileUpdateRequest;
import com.offerz.entity.Address;
import com.offerz.entity.User;
import com.offerz.repository.AddressRepository;
import com.offerz.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/user")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AddressRepository addressRepository;

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(@RequestParam String mobileNumber) {
        Optional<User> optionalUser = userRepository.findByMobileNumber(mobileNumber);
        if (optionalUser.isPresent()) {
            User user = optionalUser.get();
            List<Address> addresses = addressRepository.findByUserId(user.getId());
            return ResponseEntity.ok(new ProfileResponse(
                    user.getFullName(),
                    user.getEmail(),
                    user.getMobileNumber(),
                    user.getAvatarUrl(),
                    addresses
            ));
        }
        return ResponseEntity.status(404).body(Map.of("status", "error", "message", "User not found"));
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestParam String mobileNumber, @RequestBody ProfileUpdateRequest request) {
        Optional<User> optionalUser = userRepository.findByMobileNumber(mobileNumber);
        if (optionalUser.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("status", "error", "message", "User not found"));
        }

        User user = optionalUser.get();

        // Check email uniqueness — only validate if email has CHANGED
        String newEmail = request.getEmail();
        if (newEmail != null && !newEmail.isBlank() && !newEmail.equals(user.getEmail())) {
            if (userRepository.existsByEmail(newEmail)) {
                return ResponseEntity.badRequest().body(Map.of("status", "error", "message", "Email is already used by another account"));
            }
        }

        // Apply updates
        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName());
        }
        if (newEmail != null && !newEmail.isBlank()) {
            user.setEmail(newEmail);
        }
        if (request.getAvatarUrl() != null && !request.getAvatarUrl().isBlank()) {
            user.setAvatarUrl(request.getAvatarUrl());
        }

        userRepository.save(user);
        return ResponseEntity.ok(Map.of("status", "success", "message", "Profile updated successfully"));
    }

    @PostMapping("/address")
    public ResponseEntity<?> addAddress(@RequestParam String mobileNumber, @RequestBody AddressRequest request) {
        Optional<User> optionalUser = userRepository.findByMobileNumber(mobileNumber);
        if (optionalUser.isPresent()) {
            User user = optionalUser.get();
            Address address = new Address();
            address.setDoorNumber(request.getDoorNumber());
            address.setStreet(request.getStreet());
            address.setCity(request.getCity());
            address.setState(request.getState());
            address.setZipcode(request.getZipcode());
            address.setUser(user);
            addressRepository.save(address);
            return ResponseEntity.ok(Map.of("status", "success", "message", "Address added successfully"));
        }
        return ResponseEntity.status(404).body(Map.of("status", "error", "message", "User not found"));
    }
}
