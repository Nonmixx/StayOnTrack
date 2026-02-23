package com.stayontrack.model;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Represents a user's focus & energy profile in StayOnTrack.
 */
public class FocusProfile {
    private String id;
    private String userId;
    private LocalDateTime createdAt;
    private List<String> peakFocusTimes;
    private List<String> lowEnergyTimes;
    private String typicalStudyDuration;

    public FocusProfile() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public List<String> getPeakFocusTimes() { return peakFocusTimes; }
    public void setPeakFocusTimes(List<String> peakFocusTimes) { this.peakFocusTimes = peakFocusTimes; }

    public List<String> getLowEnergyTimes() { return lowEnergyTimes; }
    public void setLowEnergyTimes(List<String> lowEnergyTimes) { this.lowEnergyTimes = lowEnergyTimes; }

    public String getTypicalStudyDuration() { return typicalStudyDuration; }
    public void setTypicalStudyDuration(String typicalStudyDuration) { this.typicalStudyDuration = typicalStudyDuration; }
}
