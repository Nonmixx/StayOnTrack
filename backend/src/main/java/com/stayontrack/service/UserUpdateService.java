package com.stayontrack.service;

import com.google.firebase.auth.FirebaseAuthException;
import com.stayontrack.model.dto.UpdateRequest;
import org.springframework.stereotype.Service;

@Service
public class UserUpdateService {

    private final FirebaseAuthService firebaseAuthService;

    public UserUpdateService(FirebaseAuthService firebaseAuthService) {
        this.firebaseAuthService = firebaseAuthService;
    }

    /**
     * Updates password and/or contact in Firebase Auth.
     * - password → Firebase Auth password
     * - contact  → Firebase Auth phoneNumber
     * - username → Firebase Auth displayName
     */
    public void updateProfile(UpdateRequest request) throws FirebaseAuthException {
        firebaseAuthService.updateUser(
                request.getUid(),
                request.getUsername(),
                request.getContact(),
                request.getPassword()
        );
    }
}