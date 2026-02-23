package com.stayontrack.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.stayontrack.model.Deadline;
import com.stayontrack.model.FocusProfile;
import com.stayontrack.model.PlannerTask;
import com.stayontrack.model.PlannerWeek;
import com.stayontrack.model.Semester;
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
     * Generate planner for the whole semester based on semester start/end dates.
     * Called when user completes setup or adds/edits deadlines.
     */
    public PlannerWeek generateNextWeek(String userId, int availableHours) throws ExecutionException, InterruptedException {
        List<Deadline> deadlines = firestoreService.getDeadlinesByUserId(userId);
        List<Semester> semesters = firestoreService.getSemestersByUserId(userId);

        LocalDate planStart;
        LocalDate planEnd;

        LocalDate today = LocalDate.now();
        LocalDate currentWeekStart = getWeekStart(today);
        if (!semesters.isEmpty()) {
            Semester s = semesters.get(0);
            planStart = parseDate(s.getStartDate());
            planEnd = parseDate(s.getEndDate());
            if (planStart == null) planStart = currentWeekStart;
            if (planEnd == null) planEnd = planStart.plusMonths(4);
            if (planEnd.isBefore(planStart)) planEnd = planStart.plusWeeks(2);
            planStart = getWeekStart(planStart);
            // Ensure we always include current week and at least 4 weeks ahead
            if (planEnd.isBefore(currentWeekStart.plusWeeks(4))) {
                planEnd = currentWeekStart.plusWeeks(12);
            }
            // Never plan for weeks that have already passed
            if (planStart.isBefore(currentWeekStart)) {
                planStart = currentWeekStart;
            }
        } else {
            planStart = currentWeekStart;
            planEnd = planStart.plusWeeks(12);
        }

        LocalDate weekStart = planStart;
        List<PlannerWeek> created = new ArrayList<>();
        int maxWeeks = 24;
        int weekCount = 0;
        while (!weekStart.isAfter(planEnd) && weekCount < maxWeeks) {
            PlannerWeek existing = firestoreService.getPlannerWeekByDate(userId, weekStart);
            if (existing != null) {
                firestoreService.deletePlannerTasksByWeekId(existing.getId());
                firestoreService.deletePlannerWeek(existing.getId());
            }
            PlannerWeek week = new PlannerWeek(userId, weekStart, weekStart.plusDays(6), availableHours);
            firestoreService.createPlannerWeek(week);
            List<PlannerTask> tasks = distributeTasks(week, deadlines, availableHours, null, userId);
            for (PlannerTask task : tasks) {
                firestoreService.createPlannerTask(task);
            }
            created.add(week);
            weekStart = weekStart.plusWeeks(1);
            weekCount++;
        }

        return created.isEmpty() ? null : created.get(created.size() - 1);
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            if (s.contains("-") && s.length() >= 10) {
                return LocalDate.parse(s.substring(0, 10), DateTimeFormatter.ISO_LOCAL_DATE);
            }
            return null;
        } catch (Exception e) {
            return null;
        }
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
        List<PlannerTask> tasks = distributeTasks(week, deadlines, availableHours, feedback, userId);
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

    private static final String[] DAY_NAMES = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};

    private List<PlannerTask> distributeTasks(PlannerWeek week, List<Deadline> deadlines, int availableHours)
            throws ExecutionException, InterruptedException {
        return distributeTasks(week, deadlines, availableHours, null, week.getUserId());
    }

    private List<PlannerTask> distributeTasks(PlannerWeek week, List<Deadline> deadlines, int availableHours,
            String feedback, String userId) throws ExecutionException, InterruptedException {
        List<PlannerTask> tasks = new ArrayList<>();
        LocalDate weekStart = week.getWeekStartDate();
        LocalDate weekEnd = week.getWeekEndDate();

        List<String> peakFocus = null;
        List<String> lowEnergy = null;
        List<String> restDays = null;
        String typicalDuration = null;
        List<FocusProfile> focusProfiles = firestoreService.getFocusProfilesByUserId(userId);
        if (!focusProfiles.isEmpty()) {
            FocusProfile fp = focusProfiles.get(0);
            peakFocus = fp.getPeakFocusTimes();
            lowEnergy = fp.getLowEnergyTimes();
            typicalDuration = fp.getTypicalStudyDuration();
        }
        List<Semester> semesters = firestoreService.getSemestersByUserId(userId);
        if (!semesters.isEmpty() && semesters.get(0).getRestDays() != null) {
            restDays = new ArrayList<>();
            for (String d : semesters.get(0).getRestDays()) {
                try {
                    int n = Integer.parseInt(d.trim());
                    if (n >= 1 && n <= 7) restDays.add(DAY_NAMES[n - 1]);
                } catch (NumberFormatException ignored) {}
            }
        }

        if (geminiService.isAvailable()) {
            // Include deadlines in a reasonable preparation window: from 6 weeks before
            // deadline until the deadline week. Avoids tasks too far ahead or past.
            LocalDate currentWeekStart = getWeekStart(LocalDate.now());
            List<Deadline> relevantDeadlines = deadlines.stream()
                    .filter(d -> {
                        if (d.getDueDate() == null) return false;
                        LocalDate deadlineWeekStart = getWeekStart(d.getDueDate());
                        return !weekStart.isAfter(deadlineWeekStart)  // not past deadline week
                                && !weekStart.isBefore(deadlineWeekStart.minusWeeks(6))  // not too early
                                && !weekStart.isBefore(currentWeekStart);  // not in the past
                    })
                    .toList();
            List<String> suggestions = geminiService.generateTaskSuggestionsForWeek(
                    relevantDeadlines, availableHours, feedback, weekStart, peakFocus, lowEnergy, restDays, typicalDuration);
            for (String s : suggestions) {
                String[] parts = s.split("\\|");
                if (parts.length >= 4) {
                    try {
                        int day = Integer.parseInt(parts[3].trim());
                        int dayIndex = Math.max(0, Math.min(day - 1, 6));
                        LocalDate taskDate = weekStart.plusDays(dayIndex);
                        if (taskDate.isAfter(weekEnd)) continue;
                        int hour = 9, min = 0;
                        if (parts.length >= 5) {
                            String[] hm = parts[4].trim().split(":");
                            if (hm.length >= 1) hour = Integer.parseInt(hm[0].trim());
                            if (hm.length >= 2) min = Integer.parseInt(hm[1].trim());
                        }
                        LocalDateTime scheduledStart = taskDate.atTime(Math.min(23, Math.max(0, hour)), Math.min(59, Math.max(0, min)));
                        PlannerTask task = new PlannerTask(week.getId(), week.getUserId(),
                                parts[0], parts[1], parts[2], taskDate, scheduledStart, "MEDIUM");
                        tasks.add(task);
                    } catch (NumberFormatException ignored) {}
                }
            }
        }

        if (tasks.isEmpty() && !deadlines.isEmpty()) {
            LocalDate currentWeekStart = getWeekStart(LocalDate.now());
            int hoursPerDay = Math.max(1, availableHours / 7);
            int dayIndex = 0;
            for (Deadline d : deadlines) {
                if (d.getDueDate() == null) continue;
                LocalDate deadlineWeekStart = getWeekStart(d.getDueDate());
                if (weekStart.isAfter(deadlineWeekStart)
                        || weekStart.isBefore(deadlineWeekStart.minusWeeks(6))
                        || weekStart.isBefore(currentWeekStart)) continue;
                if (restDays != null && dayIndex < 7) {
                    String dayName = DAY_NAMES[dayIndex % 7];
                    if (restDays.contains(dayName)) { dayIndex++; continue; }
                }
                String taskTitle = buildTaskTitle(d);
                String duration = "1 hour";
                int hours = 1;
                if ("exam".equalsIgnoreCase(d.getType()) || "midterm".equalsIgnoreCase(d.getType()) || "final".equalsIgnoreCase(d.getType())) {
                    duration = "2 hours";
                    hours = 2;
                }
                LocalDate taskDate = weekStart.plusDays(dayIndex % 7);
                if (taskDate.isAfter(weekEnd)) taskDate = weekEnd;
                LocalDateTime scheduledStart = taskDate.atTime(9, 0);
                PlannerTask task = new PlannerTask(week.getId(), week.getUserId(), taskTitle, d.getCourse(), duration, taskDate, scheduledStart, "MEDIUM");
                tasks.add(task);
                dayIndex += (hours / Math.max(1, hoursPerDay)) + 1;
            }
        }

        // Do NOT add generic tasks - only tasks from user-added deadlines
        return tasks;
    }

    private String buildTaskTitle(Deadline d) {
        String type = d.getType() != null ? d.getType().toLowerCase() : "";
        if (type.contains("exam") || type.contains("midterm") || type.contains("final") || type.contains("quiz")) {
            return "Prepare for " + d.getTitle();
        }
        return "Work on " + d.getTitle();
    }

}
