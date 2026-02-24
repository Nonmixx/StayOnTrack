package com.stayontrack.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Represents a deadline (e.g., assignment due date, exam).
 */
public class Deadline {
    private String id;
    private String title;
    private String course;
    private LocalDate dueDate;
    private String type; // e.g., "assignment", "exam", "lab"
    private String difficulty; // e.g., "Easy", "Medium", "Hard", or "20%" for exam weight
    private Boolean isIndividual; // true = individual, false = group
    private LocalDateTime createdAt;
    private String userId;

    public Deadline() {}

    public Deadline(String title, String course, LocalDate dueDate, String type, String userId) {
        this.title = title;
        this.course = course;
        this.dueDate = dueDate;
        this.type = type;
        this.userId = userId;
        this.createdAt = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCourse() { return course; }
    public void setCourse(String course) { this.course = course; }

    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getDifficulty() { return difficulty; }
    public void setDifficulty(String difficulty) { this.difficulty = difficulty; }

    public Boolean getIsIndividual() { return isIndividual; }
    public void setIsIndividual(Boolean isIndividual) { this.isIndividual = isIndividual; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
}
