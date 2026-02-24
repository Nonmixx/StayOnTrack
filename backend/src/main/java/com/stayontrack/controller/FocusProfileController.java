package com.stayontrack.controller;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.FocusProfile;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/focus-profiles")
@CrossOrigin("*")
public class FocusProfileController {

    private final FirestoreService firestoreService;

    public FocusProfileController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<FocusProfile> createFocusProfile(@RequestBody FocusProfile profile,
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            profile.setUserId(userId);
            profile.setCreatedAt(LocalDateTime.now());
            FocusProfile created = firestoreService.createFocusProfile(profile);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<FocusProfile>> getFocusProfiles(
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<FocusProfile> list = firestoreService.getFocusProfilesByUserId(userId);
            return ResponseEntity.ok(list);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{profileId}")
    public ResponseEntity<FocusProfile> updateFocusProfile(@PathVariable String profileId,
            @RequestBody FocusProfile profile) {
        try {
            FocusProfile updated = firestoreService.updateFocusProfile(profileId, profile);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{profileId}")
    public ResponseEntity<Void> deleteFocusProfile(@PathVariable String profileId) {
        try {
            firestoreService.deleteFocusProfile(profileId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
