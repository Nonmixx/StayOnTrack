package com.stayontrack.model;

public class GroupTask {
    private int id;
    private String title;
    private String description;
    private String effort;       // "Low" | "Medium" | "High"
    private String dependencies; // task id as string, or null

    // Constructors
    public GroupTask() {}

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getEffort() { return effort; }
    public void setEffort(String effort) { this.effort = effort; }

    public String getDependencies() { return dependencies; }
    public void setDependencies(String dependencies) { this.dependencies = dependencies; }
}