package com.stayontrack.model;

import java.time.LocalDateTime;

/**
 * Represents an exam in StayOnTrack (Course & Exam Input).
 */
public class Exam {
    private String id;
    private String userId;
    private LocalDateTime createdAt;
    private String courseName;
    private String examType;
    private String date;
    private Double weightPercentage;

    public Exam() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getCourseName() { return courseName; }
    public void setCourseName(String courseName) { this.courseName = courseName; }

    public String getExamType() { return examType; }
    public void setExamType(String examType) { this.examType = examType; }

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public Double getWeightPercentage() { return weightPercentage; }
    public void setWeightPercentage(Double weightPercentage) { this.weightPercentage = weightPercentage; }
}
