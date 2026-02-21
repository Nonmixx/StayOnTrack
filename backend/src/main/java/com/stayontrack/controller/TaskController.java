package com.stayontrack.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.Task;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/tasks")
@CrossOrigin(origins = "*")
public class TaskController {

    private final FirestoreService firestoreService;

    public TaskController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<Task> createTask(@RequestBody Task task,
                                         @RequestParam(defaultValue = "default-user") String userId) {
        try {
            task.setUserId(userId);
            Task created = firestoreService.createTask(task);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Task>> getTasks(@RequestParam(defaultValue = "default-user") String userId,
                                                @RequestParam(required = false) String date) {
        try {
            List<Task> tasks;
            if (date != null && !date.isBlank()) {
                LocalDate localDate = LocalDate.parse(date);
                tasks = firestoreService.getTasksForDate(userId, localDate);
            } else {
                tasks = firestoreService.getTasksByUserId(userId);
            }
            return ResponseEntity.ok(tasks);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{taskId}")
    public ResponseEntity<Task> updateTask(@PathVariable String taskId, @RequestBody Task task) {
        try {
            Task updated = firestoreService.updateTask(taskId, task);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{taskId}")
    public ResponseEntity<Void> deleteTask(@PathVariable String taskId) {
        try {
            firestoreService.deleteTask(taskId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
