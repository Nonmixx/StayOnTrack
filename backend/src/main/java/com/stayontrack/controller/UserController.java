package com.stayontrack.controller;

import com.google.firebase.auth.FirebaseAuthException;
import com.stayontrack.model.dto.UpdateRequest;
import com.stayontrack.model.dto.UpdateResponse;
import com.stayontrack.service.UserUpdateService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {

    private final UserUpdateService userUpdateService;

    public UserController(UserUpdateService userUpdateService) {
        this.userUpdateService = userUpdateService;
    }

    /**
     * PATCH /api/user/update
     *
     * Request body:
     * {
     *   "uid":      "firebase-uid",   ← required
     *   "username": "NewName",        ← optional
     *   "contact":  "0123456789",     ← optional
     *   "password": "NewPass1!"       ← optional, updates Firebase Auth when provided
     * }
     *
     * Success (200): { "message": "Profile updated successfully" }
     * Error   (400): { "error": "<reason>" }
     * Error   (500): { "error": "Internal error" }
     */
    @PatchMapping("/update")
    public ResponseEntity<?> updateProfile(@RequestBody UpdateRequest request) {

        if (request.getUid() == null || request.getUid().isBlank()) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", "uid is required"));
        }

        try {
            userUpdateService.updateProfile(request);
            return ResponseEntity.ok(new UpdateResponse("Profile updated successfully"));

        } catch (FirebaseAuthException e) {
            String reason = switch (e.getAuthErrorCode().name()) {
                case "WEAK_PASSWORD"  -> "Password is too weak. Use at least 6 characters.";
                case "USER_NOT_FOUND" -> "User not found.";
                default -> "Failed to update profile: " + e.getMessage();
            };
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", reason));

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal error: " + e.getMessage()));
        }
    }
}