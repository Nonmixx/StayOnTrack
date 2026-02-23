package com.stayontrack.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.Exam;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/exams")
@CrossOrigin("*")
public class ExamController {

    private final FirestoreService firestoreService;

    public ExamController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<Exam> createExam(@RequestBody Exam exam,
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            exam.setUserId(userId);
            Exam created = firestoreService.createExam(exam);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Exam>> getExams(
            @RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<Exam> list = firestoreService.getExamsByUserId(userId);
            return ResponseEntity.ok(list);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{examId}")
    public ResponseEntity<Exam> updateExam(@PathVariable String examId,
            @RequestBody Exam exam) {
        try {
            Exam updated = firestoreService.updateExam(examId, exam);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{examId}")
    public ResponseEntity<Void> deleteExam(@PathVariable String examId) {
        try {
            firestoreService.deleteExam(examId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
