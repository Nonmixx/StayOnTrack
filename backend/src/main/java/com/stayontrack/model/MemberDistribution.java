package com.stayontrack.model;

import java.util.List;

public class MemberDistribution {
    private String name;
    private String initial;
    private String strengths;  // comma-separated display string
    private int taskCount;
    private List<MemberTask> tasks;

    // Constructors
    public MemberDistribution() {}

    // Getters and Setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getInitial() { return initial; }
    public void setInitial(String initial) { this.initial = initial; }

    public String getStrengths() { return strengths; }
    public void setStrengths(String strengths) { this.strengths = strengths; }

    public int getTaskCount() { return taskCount; }
    public void setTaskCount(int taskCount) { this.taskCount = taskCount; }

    public List<MemberTask> getTasks() { return tasks; }
    public void setTasks(List<MemberTask> tasks) { this.tasks = tasks; }
}