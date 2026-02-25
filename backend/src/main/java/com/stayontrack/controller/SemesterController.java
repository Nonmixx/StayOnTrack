package com.stayontrack.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.Semester;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/semesters")
@CrossOrigin("*")
public class SemesterController {

    private final FirestoreService firestoreService;

    public SemesterController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<Semester> createSemester(@RequestBody Semester semester,
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            semester.setUserId(userId);
            // If a semester for this user already exists, update it to avoid duplicates when navigating back and forth.
            List<Semester> existing = firestoreService.getSemestersByUserId(userId);
            if (!existing.isEmpty()) {
                String existingId = existing.get(0).getId();
                Semester updated = firestoreService.updateSemester(existingId, semester);
                return ResponseEntity.ok(updated);
            }
            Semester created = firestoreService.createSemester(semester);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Semester>> getSemesters(
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<Semester> list = firestoreService.getSemestersByUserId(userId);
            return ResponseEntity.ok(list);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{semesterId}")
    public ResponseEntity<Semester> updateSemester(@PathVariable String semesterId,
            @RequestBody Semester semester) {
        try {
            Semester updated = firestoreService.updateSemester(semesterId, semester);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{semesterId}")
    public ResponseEntity<Void> deleteSemester(@PathVariable String semesterId) {
        try {
            firestoreService.deleteSemester(semesterId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
