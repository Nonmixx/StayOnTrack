package com.stayontrack.controller;

import java.util.Collections;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.Deadline;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/deadlines")
@CrossOrigin("*")
public class DeadlineController {

    private final FirestoreService firestoreService;

    public DeadlineController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<Deadline> createDeadline(@RequestBody Deadline deadline,
                                                   @RequestParam(defaultValue = "default-user") String userId) {
        try {
            deadline.setUserId(userId);
            Deadline created = firestoreService.createDeadline(deadline);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Deadline>> getDeadlines(@RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<Deadline> deadlines = firestoreService.getDeadlinesByUserId(userId);
            return ResponseEntity.ok(deadlines);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    @PutMapping("/{deadlineId}")
    public ResponseEntity<Deadline> updateDeadline(@PathVariable String deadlineId,
                                                    @RequestBody Deadline deadline,
                                                    @RequestParam(defaultValue = "default-user") String userId) {
        try {
            deadline.setUserId(userId);
            Deadline updated = firestoreService.updateDeadline(deadlineId, deadline);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{deadlineId}")
    public ResponseEntity<Void> deleteDeadline(@PathVariable String deadlineId) {
        try {
            firestoreService.deleteDeadline(deadlineId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
