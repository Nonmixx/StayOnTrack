package com.stayontrack.model;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Represents a semester in StayOnTrack (Semester Setup).
 */
public class Semester {
    private String id;
    private String userId;
    private LocalDateTime createdAt;
    private String semesterName;
    private String startDate;
    private String endDate;
    private String studyMode;
    private List<String> restDays;

    public Semester() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getSemesterName() { return semesterName; }
    public void setSemesterName(String semesterName) { this.semesterName = semesterName; }

    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }

    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }

    public String getStudyMode() { return studyMode; }
    public void setStudyMode(String studyMode) { this.studyMode = studyMode; }

    public List<String> getRestDays() { return restDays; }
    public void setRestDays(List<String> restDays) { this.restDays = restDays; }
}
