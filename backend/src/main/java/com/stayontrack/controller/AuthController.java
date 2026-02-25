package com.stayontrack.controller;

import com.google.firebase.auth.FirebaseAuthException;
import com.stayontrack.model.dto.LoginRequest;
import com.stayontrack.model.dto.LoginResponse;
import com.stayontrack.model.dto.RegisterRequest;
import com.stayontrack.model.dto.RegisterResponse;
import com.stayontrack.service.FirebaseAuthService;
import com.stayontrack.service.FirebaseLoginService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final FirebaseAuthService firebaseAuthService;
    private final FirebaseLoginService firebaseLoginService;

    public AuthController(FirebaseAuthService firebaseAuthService,
                          FirebaseLoginService firebaseLoginService) {
        this.firebaseAuthService = firebaseAuthService;
        this.firebaseLoginService = firebaseLoginService;
    }

    /**
     * POST /api/auth/register
     *
     * Request body:
     * {
     *   "username": "JohnDoe",
     *   "email": "john@example.com",
     *   "password": "SecurePass1!"
     * }
     *
     * Success (201):
     * {
     *   "uid": "firebase-uid",
     *   "email": "john@example.com",
     *   "username": "JohnDoe",
     *   "message": "User registered successfully"
     * }
     *
     * Error (409) – email already registered:
     * { "error": "This email is already registered" }
     *
     * Error (400) – Firebase / validation failure:
     * { "error": "<reason>" }
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        if (firebaseAuthService.emailExists(request.getEmail())) {
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "This email is already registered"));
        }

        try {
            RegisterResponse response = firebaseAuthService.registerUser(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);

        } catch (FirebaseAuthException e) {
            String reason = switch (e.getAuthErrorCode().name()) {
                case "EMAIL_ALREADY_EXISTS" -> "This email is already registered";
                case "INVALID_EMAIL"        -> "Enter a valid email address";
                case "WEAK_PASSWORD"        -> "Password does not meet Firebase requirements";
                default -> "Registration failed: " + e.getMessage();
            };
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", reason));
        }
    }

    /**
     * POST /api/auth/login
     *
     * Request body:
     * {
     *   "email": "john@example.com",
     *   "password": "SecurePass1!"
     * }
     *
     * Success (200):
     * {
     *   "uid": "firebase-uid",
     *   "email": "john@example.com",
     *   "username": "JohnDoe",
     *   "idToken": "eyJ...",
     *   "message": "Login successful"
     * }
     *
     * Error (401) – wrong credentials:
     * { "error": "Incorrect email or password. Please try again." }
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        if (request.getEmail() == null || request.getEmail().isBlank()) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", "Email cannot be empty"));
        }
        if (request.getPassword() == null || request.getPassword().isBlank()) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", "Password cannot be empty"));
        }

        try {
            LoginResponse response = firebaseLoginService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/auth/check-email?email=john@example.com
     *
     * Response: { "exists": true|false }
     */
    @GetMapping("/check-email")
    public ResponseEntity<Map<String, Boolean>> checkEmail(@RequestParam String email) {
        return ResponseEntity.ok(Map.of("exists", firebaseAuthService.emailExists(email)));
    }
}