package com.stayontrack.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.Assignment;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/assignments")
@CrossOrigin("*")
public class AssignmentController {

    private final FirestoreService firestoreService;

    public AssignmentController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<Assignment> createAssignment(@RequestBody Assignment assignment,
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            assignment.setUserId(userId);
            Assignment created = firestoreService.createAssignment(assignment);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Assignment>> getAssignments(
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<Assignment> list = firestoreService.getAssignmentsByUserId(userId);
            return ResponseEntity.ok(list);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{assignmentId}")
    public ResponseEntity<Assignment> updateAssignment(@PathVariable String assignmentId,
            @RequestBody Assignment assignment) {
        try {
            Assignment updated = firestoreService.updateAssignment(assignmentId, assignment);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{assignmentId}")
    public ResponseEntity<Void> deleteAssignment(@PathVariable String assignmentId) {
        try {
            firestoreService.deleteAssignment(assignmentId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
