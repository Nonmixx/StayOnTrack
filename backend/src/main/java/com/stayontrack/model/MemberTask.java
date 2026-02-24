package com.stayontrack.model;

public class MemberTask {
    private String title;
    private String description;
    private String effort;
    private String reason;       // why this member was assigned this task
    private String dependencies;

    // Constructors
    public MemberTask() {}

    // Getters and Setters
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getEffort() { return effort; }
    public void setEffort(String effort) { this.effort = effort; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getDependencies() { return dependencies; }
    public void setDependencies(String dependencies) { this.dependencies = dependencies; }
}