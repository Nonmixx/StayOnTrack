package com.stayontrack.controller;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.PlannerTask;
import com.stayontrack.model.PlannerWeek;
import com.stayontrack.model.dto.WeeklySummary;
import com.stayontrack.service.FirestoreService;
import com.stayontrack.service.PlannerEngineService;

/**
 * Member 2 - Planner Engine APIs.
 */
@RestController
@RequestMapping("/api/planner")
@CrossOrigin("*")
public class PlannerController {

    private final PlannerEngineService plannerEngine;
    private final FirestoreService firestoreService;

    public PlannerController(PlannerEngineService plannerEngine, FirestoreService firestoreService) {
        this.plannerEngine = plannerEngine;
        this.firestoreService = firestoreService;
    }

    /**
     * Get today's tasks for Home page.
     */
    @GetMapping("/today")
    public ResponseEntity<List<PlannerTask>> getTodaysTasks(
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<PlannerTask> tasks = plannerEngine.getTodaysTasks(userId);
            return ResponseEntity.ok(tasks);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    /**
     * Get weekly summary (tasks completed, overdue, completion rate).
     */
    @GetMapping("/weekly-summary")
    public ResponseEntity<WeeklySummary> getWeeklySummary(
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            WeeklySummary summary = plannerEngine.getWeeklySummary(userId);
            return ResponseEntity.ok(summary);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Toggle task completion.
     */
    @PatchMapping("/tasks/{taskId}/complete")
    public ResponseEntity<PlannerTask> toggleTaskCompletion(
            @PathVariable String taskId,
            @RequestParam boolean completed) {
        try {
            PlannerTask task = plannerEngine.toggleTaskCompletion(taskId, completed);
            return ResponseEntity.ok(task);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Generate initial next week plan (e.g. after setup).
     */
    @PostMapping("/generate")
    public ResponseEntity<PlannerWeek> generateNextWeek(
            @RequestParam(defaultValue = "default-user") String userId,
            @RequestParam(defaultValue = "20") int availableHours) {
        try {
            PlannerWeek week = plannerEngine.generateNextWeek(userId, availableHours);
            return week != null ? ResponseEntity.ok(week) : ResponseEntity.internalServerError().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Regenerate next week (from Weekly Check-In).
     * Saves feedback and regenerates plan with new available hours.
     */
    @PostMapping("/regenerate")
    public ResponseEntity<PlannerWeek> regenerateNextWeek(
            @RequestParam(defaultValue = "default-user") String userId,
            @RequestBody(required = false) com.stayontrack.model.dto.RegenerateRequest body) {
        try {
            int availableHours = (body != null && body.getAvailableStudyHoursNextWeek() > 0)
                    ? body.getAvailableStudyHoursNextWeek() : 20;
            String feedback = body != null ? body.getFeedback() : null;
            if (feedback != null && !feedback.isBlank()) {
                var checkIn = new com.stayontrack.model.WeeklyCheckIn(userId, feedback, availableHours);
                firestoreService.createWeeklyCheckIn(checkIn);
            }
            PlannerWeek week = plannerEngine.regenerateNextWeek(userId, availableHours, feedback);
            return ResponseEntity.ok(week);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get tasks for a specific week (for Week Planner page).
     */
    @GetMapping("/week")
    public ResponseEntity<List<PlannerTask>> getWeekTasks(
            @RequestParam(defaultValue = "default-user") String userId,
            @RequestParam String weekStartDate) {
        try {
            LocalDate weekStart = LocalDate.parse(weekStartDate);
            List<PlannerTask> tasks = firestoreService.getPlannerTasksForWeek(userId, weekStart);
            return ResponseEntity.ok(tasks);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get planner task count for a month (for Monthly view workload summary).
     */
    @GetMapping("/month-tasks")
    public ResponseEntity<Integer> getMonthTaskCount(
            @RequestParam(defaultValue = "default-user") String userId,
            @RequestParam int year,
            @RequestParam int month) {
        try {
            int count = firestoreService.getPlannerTaskCountForMonth(userId, year, month);
            return ResponseEntity.ok(count);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.ok(0);
        }
    }
}
