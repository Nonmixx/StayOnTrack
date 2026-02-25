package com.stayontrack.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import com.stayontrack.model.dto.LoginRequest;
import com.stayontrack.model.dto.LoginResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
public class FirebaseLoginService {

    @Value("${firebase.api.key}")
    private String firebaseApiKey;

    private final RestTemplate restTemplate;

    public FirebaseLoginService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Verifies email + password via Firebase REST API.
     * Reads username (displayName) and contact (phoneNumber) from Firebase Auth.
     */
    public LoginResponse login(LoginRequest request) {
        String url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + firebaseApiKey;

        Map<String, Object> body = new HashMap<>();
        body.put("email",             request.getEmail());
        body.put("password",          request.getPassword());
        body.put("returnSecureToken", true);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
            Map<?, ?> responseBody = response.getBody();

            if (responseBody == null) throw new RuntimeException("Empty response from Firebase");

            String idToken = (String) responseBody.get("idToken");
            String uid     = (String) responseBody.get("localId");

            // ✅ Read username and contact from Firebase Auth
            String username = "";
            String contact  = "";
            try {
                UserRecord userRecord = FirebaseAuth.getInstance().getUser(uid);
                username = userRecord.getDisplayName()  != null ? userRecord.getDisplayName()  : "";
                contact  = userRecord.getPhoneNumber()  != null ? userRecord.getPhoneNumber()  : "";
            } catch (FirebaseAuthException ignored) {}

            return new LoginResponse(uid, request.getEmail(), username, contact, idToken, "Login successful");

        } catch (HttpClientErrorException e) {
            String reason = e.getResponseBodyAsString();
            if (reason.contains("INVALID_PASSWORD") || reason.contains("EMAIL_NOT_FOUND")
                    || reason.contains("INVALID_LOGIN_CREDENTIALS")) {
                throw new RuntimeException("Incorrect email or password. Please try again.");
            }
            if (reason.contains("TOO_MANY_ATTEMPTS_TRY_LATER")) {
                throw new RuntimeException("Too many failed attempts. Please try again later.");
            }
            if (reason.contains("USER_DISABLED")) {
                throw new RuntimeException("This account has been disabled.");
            }
            throw new RuntimeException("Login failed. Please try again.");
        }
    }
}