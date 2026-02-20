package com.stayontrack.model.dto;

/**
 * Request body for planner regeneration (Weekly Check-In).
 */
public class RegenerateRequest {
    private String feedback;
    private int availableStudyHoursNextWeek = 20;

    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }

    public int getAvailableStudyHoursNextWeek() { return availableStudyHoursNextWeek; }
    public void setAvailableStudyHoursNextWeek(int availableStudyHoursNextWeek) {
        this.availableStudyHoursNextWeek = availableStudyHoursNextWeek;
    }
}
