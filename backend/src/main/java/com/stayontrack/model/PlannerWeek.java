package com.stayontrack.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Represents a week in the AI-generated planner.
 * Member 2 - Planner Engine.
 */
public class PlannerWeek {
    private String id;
    private String userId;
    private LocalDate weekStartDate;
    private LocalDate weekEndDate;
    private int availableHours;
    private LocalDateTime createdAt;

    public PlannerWeek() {}

    public PlannerWeek(String userId, LocalDate weekStartDate, LocalDate weekEndDate, int availableHours) {
        this.userId = userId;
        this.weekStartDate = weekStartDate;
        this.weekEndDate = weekEndDate;
        this.availableHours = availableHours;
        this.createdAt = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public LocalDate getWeekStartDate() { return weekStartDate; }
    public void setWeekStartDate(LocalDate weekStartDate) { this.weekStartDate = weekStartDate; }

    public LocalDate getWeekEndDate() { return weekEndDate; }
    public void setWeekEndDate(LocalDate weekEndDate) { this.weekEndDate = weekEndDate; }

    public int getAvailableHours() { return availableHours; }
    public void setAvailableHours(int availableHours) { this.availableHours = availableHours; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
