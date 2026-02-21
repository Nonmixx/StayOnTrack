package com.stayontrack.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.stayontrack.model.Deadline;
import com.stayontrack.model.PlannerTask;
import com.stayontrack.model.PlannerWeek;
import com.stayontrack.model.dto.WeeklySummary;

/**
 * Member 2 - Planner Engine.
 * Generates and regenerates weekly schedules from deadlines.
 */
@Service
public class PlannerEngineService {

    private final FirestoreService firestoreService;
    private final GeminiService geminiService;

    public PlannerEngineService(FirestoreService firestoreService, GeminiService geminiService) {
        this.firestoreService = firestoreService;
        this.geminiService = geminiService;
    }

    /**
     * Generate next week's planner from deadlines.
     * Called when user completes setup or adds/edits deadlines.
     */
    public PlannerWeek generateNextWeek(String userId, int availableHours) throws ExecutionException, InterruptedException {
        LocalDate nextMonday = getNextMonday(LocalDate.now());
        LocalDate nextSunday = nextMonday.plusDays(6);

        PlannerWeek week = new PlannerWeek(userId, nextMonday, nextSunday, availableHours);
        firestoreService.createPlannerWeek(week);

        List<Deadline> deadlines = firestoreService.getDeadlinesByUserId(userId);
        List<PlannerTask> tasks = distributeTasks(week, deadlines, availableHours, null);

        for (PlannerTask task : tasks) {
            firestoreService.createPlannerTask(task);
        }

        return week;
    }

    /**
     * Regenerate next week only. Called from Weekly Check-In.
     */
    public PlannerWeek regenerateNextWeek(String userId, int availableHours, String feedback) throws ExecutionException, InterruptedException {
        LocalDate nextMonday = getNextMonday(LocalDate.now());
        PlannerWeek existing = firestoreService.getPlannerWeekByDate(userId, nextMonday);

        if (existing != null) {
            firestoreService.deletePlannerTasksByWeekId(existing.getId());
            firestoreService.deletePlannerWeek(existing.getId());
        }

        PlannerWeek week = new PlannerWeek(userId, getNextMonday(LocalDate.now()), getNextMonday(LocalDate.now()).plusDays(6), availableHours);
        firestoreService.createPlannerWeek(week);
        List<Deadline> deadlines = firestoreService.getDeadlinesByUserId(userId);
        List<PlannerTask> tasks = distributeTasks(week, deadlines, availableHours, feedback);
        for (PlannerTask task : tasks) {
            firestoreService.createPlannerTask(task);
        }
        return week;
    }

    /**
     * Get today's tasks for Home page.
     */
    public List<PlannerTask> getTodaysTasks(String userId) throws ExecutionException, InterruptedException {
        return firestoreService.getPlannerTasksForDate(userId, LocalDate.now());
    }

    /**
     * Get weekly summary (tasks completed, overdue, completion rate).
     */
    public WeeklySummary getWeeklySummary(String userId) throws ExecutionException, InterruptedException {
        LocalDate weekStart = getWeekStart(LocalDate.now());
        List<PlannerTask> tasks = firestoreService.getPlannerTasksForWeek(userId, weekStart);

        int completed = (int) tasks.stream().filter(PlannerTask::isCompleted).count();
        int overdue = (int) tasks.stream()
                .filter(t -> !t.isCompleted() && t.getDueDate().isBefore(LocalDate.now()))
                .count();
        int total = tasks.size();

        return new WeeklySummary(completed, total, overdue);
    }

    /**
     * Toggle task completion.
     */
    public PlannerTask toggleTaskCompletion(String taskId, boolean completed) throws ExecutionException, InterruptedException {
        PlannerTask task = new PlannerTask();
        task.setCompleted(completed);
        return firestoreService.updatePlannerTask(taskId, task);
    }

    private LocalDate getNextMonday(LocalDate from) {
        LocalDate d = from;
        while (d.getDayOfWeek() != DayOfWeek.MONDAY) {
            d = d.plusDays(1);
        }
        return d;
    }

    private LocalDate getWeekStart(LocalDate date) {
        return date.with(DayOfWeek.MONDAY);
    }

    /**
     * Distribute tasks across the week based on deadlines and available hours.
     * Uses Google Gemini AI when API key is configured; otherwise rule-based.
     */
    private List<PlannerTask> distributeTasks(PlannerWeek week, List<Deadline> deadlines, int availableHours) {
        return distributeTasks(week, deadlines, availableHours, null);
    }

    private List<PlannerTask> distributeTasks(PlannerWeek week, List<Deadline> deadlines, int availableHours, String feedback) {
        List<PlannerTask> tasks = new ArrayList<>();
        LocalDate weekStart = week.getWeekStartDate();
        LocalDate weekEnd = week.getWeekEndDate();

        if (geminiService.isAvailable()) {
            List<String> suggestions = geminiService.generateTaskSuggestions(deadlines, availableHours, feedback);
            for (int i = 0; i < suggestions.size(); i++) {
                String[] parts = suggestions.get(i).split("\\|");
                if (parts.length >= 3) {
                    int dayIndex = Math.min(i % 5, 4);
                    LocalDate taskDate = weekStart.plusDays(dayIndex);
                    if (!taskDate.isAfter(weekEnd)) {
                        PlannerTask task = new PlannerTask(week.getId(), week.getUserId(),
                                parts[0], parts[1], parts[2], taskDate, "MEDIUM");
                        tasks.add(task);
                    }
                }
            }
        }

        if (tasks.isEmpty() && !deadlines.isEmpty()) {
            int hoursPerDay = Math.max(1, availableHours / 7);
            int dayIndex = 0;
            for (Deadline d : deadlines) {
                if (d.getDueDate() == null || d.getDueDate().isAfter(weekEnd)) continue;
                String taskTitle = buildTaskTitle(d);
                String duration = "1 hour";
                int hours = 1;
                if ("exam".equalsIgnoreCase(d.getType()) || "midterm".equalsIgnoreCase(d.getType()) || "final".equalsIgnoreCase(d.getType())) {
                    duration = "2 hours";
                    hours = 2;
                }
                LocalDate taskDate = weekStart.plusDays(dayIndex % 7);
                if (taskDate.isAfter(weekEnd)) taskDate = weekEnd;
                PlannerTask task = new PlannerTask(week.getId(), week.getUserId(), taskTitle, d.getCourse(), duration, taskDate, "MEDIUM");
                tasks.add(task);
                dayIndex += (hours / Math.max(1, hoursPerDay)) + 1;
            }
        }

        if (tasks.isEmpty()) {
            tasks.addAll(createDefaultTasks(week, weekStart, availableHours));
        }

        return tasks;
    }

    private String buildTaskTitle(Deadline d) {
        String type = d.getType() != null ? d.getType().toLowerCase() : "";
        if (type.contains("exam") || type.contains("midterm") || type.contains("final") || type.contains("quiz")) {
            return "Prepare for " + d.getTitle();
        }
        return "Work on " + d.getTitle();
    }

    private List<PlannerTask> createDefaultTasks(PlannerWeek week, LocalDate weekStart, int availableHours) {
        List<PlannerTask> tasks = new ArrayList<>();
        String[] defaultTitles = {"Review lecture notes", "Practice problems", "Read textbook", "Assignment work"};
        String[] courses = {"General", "Study"};
        int hoursPerDay = Math.max(1, availableHours / 7);
        String duration = hoursPerDay + " hour" + (hoursPerDay > 1 ? "s" : "");

        for (int i = 0; i < 5; i++) {
            LocalDate date = weekStart.plusDays(i);
            if (date.getDayOfWeek() == DayOfWeek.SATURDAY || date.getDayOfWeek() == DayOfWeek.SUNDAY) continue;

            PlannerTask task = new PlannerTask(week.getId(), week.getUserId(),
                    defaultTitles[i % defaultTitles.length], courses[i % 2], duration, date, "MEDIUM");
            tasks.add(task);
        }
        return tasks;
    }
}
