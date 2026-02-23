package com.stayontrack.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.stayontrack.model.WeeklyCheckIn;
import com.stayontrack.service.FirestoreService;

@RestController
@RequestMapping("/api/weekly-checkins")
@CrossOrigin("*")
public class WeeklyCheckInController {

    private final FirestoreService firestoreService;

    public WeeklyCheckInController(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
    }

    @PostMapping
    public ResponseEntity<WeeklyCheckIn> createCheckIn(@RequestBody WeeklyCheckIn checkIn,
                                                       @RequestParam(defaultValue = "default-user") String userId) {
        try {
            checkIn.setUserId(userId);
            WeeklyCheckIn created = firestoreService.createWeeklyCheckIn(checkIn);
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<WeeklyCheckIn>> getCheckIns(@RequestParam(defaultValue = "default-user") String userId) {
        try {
            List<WeeklyCheckIn> checkIns = firestoreService.getWeeklyCheckInsByUserId(userId);
            return ResponseEntity.ok(checkIns);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
