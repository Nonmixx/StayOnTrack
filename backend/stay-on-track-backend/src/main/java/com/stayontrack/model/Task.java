package com.stayontrack.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Represents a task in StayOnTrack (e.g., "Review Chapter 5", "Practice Calculus").
 */
public class Task {
    private String id;
    private String title;
    private String course;
    private String duration;
    private boolean completed;
    private LocalDate dueDate;
    private LocalDateTime createdAt;
    private String userId;

    public Task() {}

    public Task(String title, String course, String duration, boolean completed, LocalDate dueDate, String userId) {
        this.title = title;
        this.course = course;
        this.duration = duration;
        this.completed = completed;
        this.dueDate = dueDate;
        this.userId = userId;
        this.createdAt = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

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

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
}
