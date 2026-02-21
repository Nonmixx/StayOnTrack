package com.stayontrack.model;

import java.time.LocalDateTime;

/**
 * Represents a weekly check-in submission from the user.
 */
public class WeeklyCheckIn {
    private String id;
    private String userId;
    private String feedback;
    private int availableStudyHoursNextWeek;
    private LocalDateTime createdAt;

    public WeeklyCheckIn() {}

    public WeeklyCheckIn(String userId, String feedback, int availableStudyHoursNextWeek) {
        this.userId = userId;
        this.feedback = feedback;
        this.availableStudyHoursNextWeek = availableStudyHoursNextWeek;
        this.createdAt = LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }

    public int getAvailableStudyHoursNextWeek() { return availableStudyHoursNextWeek; }
    public void setAvailableStudyHoursNextWeek(int availableStudyHoursNextWeek) {
        this.availableStudyHoursNextWeek = availableStudyHoursNextWeek;
    }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
