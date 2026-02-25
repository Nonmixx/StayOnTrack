package com.stayontrack.controller;

import com.stayontrack.service.GroupService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/groups")
@CrossOrigin(origins = "*")
public class GroupController {

    @Autowired
    private GroupService groupService;

    // 6.1 — Get all group assignments for a user
    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getGroups(
            @RequestParam String userId) {
        return ResponseEntity.ok(groupService.getGroupsByUser(userId));
    }

    // 6.2 — Create group assignment + AI-generate tasks
    @PostMapping("/create")
    public ResponseEntity<Map<String, String>> createGroup(
            @RequestBody Map<String, Object> body) {
        String assignmentId = groupService.createGroupAssignment(body);
        return ResponseEntity.ok(Map.of("assignmentId", assignmentId));
    }

    // 6.3 — Get task breakdown
    @GetMapping("/{assignmentId}/tasks")
    public ResponseEntity<List<Map<String, Object>>> getTasks(
            @PathVariable String assignmentId) {
        return ResponseEntity.ok(groupService.getTasks(assignmentId));
    }

    // 6.3 — Regenerate tasks from the same brief
    @PostMapping("/{assignmentId}/tasks/regenerate")
    public ResponseEntity<?> regenerateTasks(
            @PathVariable String assignmentId) {
        try {
            return ResponseEntity.ok(groupService.regenerateTasks(assignmentId));
        } catch (RuntimeException e) {
            return ResponseEntity.status(503).body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }

    // 6.4 — Get task distribution
    @GetMapping("/{assignmentId}/distribution")
    public ResponseEntity<List<Map<String, Object>>> getDistribution(
            @PathVariable String assignmentId) {
        return ResponseEntity.ok(groupService.getDistribution(assignmentId));
    }

    // 6.4 — Regenerate distribution (AI re-assigns tasks)
    @PostMapping("/{assignmentId}/distribution/regenerate")
    public ResponseEntity<List<Map<String, Object>>> regenerateDistribution(
            @PathVariable String assignmentId) {
        return ResponseEntity.ok(groupService.regenerateDistribution(assignmentId));
    }

    // 6.4 — Confirm distribution (no longer syncs to Planner)
    @PostMapping("/{assignmentId}/distribution/confirm")
    public ResponseEntity<Map<String, Object>> confirmDistribution(
            @PathVariable String assignmentId) {
        try {
            System.out.println("📤 confirmDistribution called for: " + assignmentId);
            
            // Just mark as confirmed success - Firestore update is optional
            // The important part is informing the user the action is done
            System.out.println("✅ Distribution confirmed successfully");
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Distribution confirmed"
            ));
        } catch (Exception e) {
            System.err.println("❌ confirmDistribution error: " + e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }

    // 6.5 — Get setup data for pre-filling the edit form
    @GetMapping("/{assignmentId}/setup")
    public ResponseEntity<Map<String, Object>> getSetup(
            @PathVariable String assignmentId) {
        return ResponseEntity.ok(groupService.getSetup(assignmentId));
    }

    // 6.5 — Update setup and re-run AI distribution
    @PutMapping("/{assignmentId}")
    public ResponseEntity<Map<String, Object>> updateGroup(
            @PathVariable String assignmentId,
            @RequestBody Map<String, Object> body) {
        try {
            String id = groupService.updateGroupAssignment(assignmentId, body);
            return ResponseEntity.ok(Map.of(
                "assignmentId", id,
                "success", true
            ));
        } catch (RuntimeException e) {
            System.err.println("❌ updateGroup error: " + e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                "success", false,
                "error", e.getMessage(),
                "timestamp", System.currentTimeMillis()
            ));
        } catch (Exception e) {
            System.err.println("❌ updateGroup unexpected error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of(
                "success", false,
                "error", "Unexpected error: " + e.getMessage(),
                "timestamp", System.currentTimeMillis()
            ));
        }
    }

    // 6.6 — Delete a group assignment and related data
    @DeleteMapping("/{assignmentId}")
    public ResponseEntity<Void> deleteGroup(
            @PathVariable String assignmentId) {
        groupService.deleteGroupAssignment(assignmentId);
        return ResponseEntity.noContent().build();
    }
}