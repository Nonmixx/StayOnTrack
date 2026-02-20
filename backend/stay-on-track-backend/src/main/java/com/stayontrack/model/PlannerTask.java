package com.stayontrack.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * AI-generated task within a planner week.
 * Member 2 - Planner Engine.
 */
public class PlannerTask {
    private String id;
    private String plannerWeekId;
    private String userId;
    private String title;
    private String course;
    private String duration;
    private boolean completed;
    private LocalDate dueDate;
    private String difficulty; // LOW, MEDIUM, HIGH
    private String status;     // ON_TRACK, AT_RISK
    private LocalDateTime createdAt;

    public PlannerTask() {}

    public PlannerTask(String plannerWeekId, String userId, String title, String course,
                       String duration, LocalDate dueDate, String difficulty) {
        this.plannerWeekId = plannerWeekId;
        this.userId = userId;
        this.title = title;
        this.course = course;
        this.duration = duration;
        this.dueDate = dueDate;
        this.difficulty = difficulty != null ? difficulty : "MEDIUM";
        this.status = "ON_TRACK";
        this.completed = false;
        this.createdAt = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getPlannerWeekId() { return plannerWeekId; }
    public void setPlannerWeekId(String plannerWeekId) { this.plannerWeekId = plannerWeekId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCourse() { return course; }
    public void setCourse(String course) { this.course = course; }

    public String getDuration() { return duration; }
    public void setDuration(String duration) { this.duration = duration; }

    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }

    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }

    public String getDifficulty() { return difficulty; }
    public void setDifficulty(String difficulty) { this.difficulty = difficulty; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
