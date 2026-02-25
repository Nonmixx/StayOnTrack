package com.stayontrack.service;

import org.springframework.stereotype.Service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import com.stayontrack.model.dto.RegisterRequest;
import com.stayontrack.model.dto.RegisterResponse;

@Service
public class FirebaseAuthService {

    /**
     * Creates user in Firebase Authentication.
     */
    public RegisterResponse registerUser(RegisterRequest request) throws FirebaseAuthException {
        UserRecord.CreateRequest createRequest = new UserRecord.CreateRequest()
                .setEmail(request.getEmail())
                .setPassword(request.getPassword())
                .setDisplayName(request.getUsername())
                .setEmailVerified(false)
                .setDisabled(false);

        UserRecord userRecord = FirebaseAuth.getInstance().createUser(createRequest);

        return new RegisterResponse(
                userRecord.getUid(),
                userRecord.getEmail(),
                userRecord.getDisplayName(),
                "User registered successfully"
        );
    }

    /**
     * Updates username, contact, and/or password in Firebase Auth.
     * - username → displayName
     * - contact  → phoneNumber (stored as-is, e.g. "+60123456789")
     * - password → Firebase Auth password hash
     * Any null/blank field is skipped (not overwritten).
     */
    public void updateUser(String uid, String username, String contact, String password)
            throws FirebaseAuthException {

        UserRecord.UpdateRequest updateRequest = new UserRecord.UpdateRequest(uid);

        if (username != null && !username.isBlank()) {
            updateRequest.setDisplayName(username.trim());
        }
        if (contact != null && !contact.isBlank()) {
            // Firebase requires E.164 format for phoneNumber e.g. +60123456789
            // If user enters without +, we add the Malaysian prefix as a fallback
            String phone = contact.trim();
            if (!phone.startsWith("+")) {
                phone = "+6" + phone; // e.g. 0123456789 → +60123456789
            }
            updateRequest.setPhoneNumber(phone);
        }
        if (password != null && !password.isBlank()) {
            updateRequest.setPassword(password);
        }

        FirebaseAuth.getInstance().updateUser(updateRequest);
    }

    /**
     * Checks whether an email is already registered in Firebase Auth.
     */
    public boolean emailExists(String email) {
        try {
            FirebaseAuth.getInstance().getUserByEmail(email);
            return true;
        } catch (FirebaseAuthException e) {
            return false;
        }
    }
}