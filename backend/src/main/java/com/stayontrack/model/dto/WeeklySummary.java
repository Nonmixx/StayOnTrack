package com.stayontrack.model.dto;

/**
 * Auto-calculated weekly summary for the check-in page.
 */
public class WeeklySummary {
    private int tasksCompleted;
    private int totalTasks;
    private int overdueTasks;
    private int completionRatePercent;

    public WeeklySummary() {}

    public WeeklySummary(int tasksCompleted, int totalTasks, int overdueTasks) {
        this.tasksCompleted = tasksCompleted;
        this.totalTasks = totalTasks;
        this.overdueTasks = overdueTasks;
        this.completionRatePercent = totalTasks > 0 ? (tasksCompleted * 100 / totalTasks) : 0;
    }

    public int getTasksCompleted() { return tasksCompleted; }
    public void setTasksCompleted(int tasksCompleted) { this.tasksCompleted = tasksCompleted; }

    public int getTotalTasks() { return totalTasks; }
    public void setTotalTasks(int totalTasks) { this.totalTasks = totalTasks; }

    public int getOverdueTasks() { return overdueTasks; }
    public void setOverdueTasks(int overdueTasks) { this.overdueTasks = overdueTasks; }

    public int getCompletionRatePercent() { return completionRatePercent; }
    public void setCompletionRatePercent(int completionRatePercent) { this.completionRatePercent = completionRatePercent; }
}
