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
    public ResponseEntity<List<Map<String, Object>>> regenerateTasks(
            @PathVariable String assignmentId) {
        return ResponseEntity.ok(groupService.regenerateTasks(assignmentId));
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

    // 6.4 — Confirm distribution and sync to Planner
    @PostMapping("/{assignmentId}/distribution/confirm")
    public ResponseEntity<Void> confirmDistribution(
            @PathVariable String assignmentId,
            @RequestParam String userId) {
        groupService.confirmAndSync(assignmentId, userId);
        return ResponseEntity.ok().build();
    }

    // 6.5 — Get setup data for pre-filling the edit form
    @GetMapping("/{assignmentId}/setup")
    public ResponseEntity<Map<String, Object>> getSetup(
            @PathVariable String assignmentId) {
        return ResponseEntity.ok(groupService.getSetup(assignmentId));
    }

    // 6.5 — Update setup and re-run AI distribution
    @PutMapping("/{assignmentId}")
    public ResponseEntity<Map<String, String>> updateGroup(
            @PathVariable String assignmentId,
            @RequestBody Map<String, Object> body) {
        String id = groupService.updateGroupAssignment(assignmentId, body);
        return ResponseEntity.ok(Map.of("assignmentId", id));
    }
}