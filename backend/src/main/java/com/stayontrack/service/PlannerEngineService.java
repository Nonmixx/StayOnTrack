package com.stayontrack.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.stayontrack.model.Deadline;
import com.stayontrack.model.FocusProfile;
import com.stayontrack.model.PlannerTask;
import com.stayontrack.model.PlannerWeek;
import com.stayontrack.model.Semester;
import com.stayontrack.model.dto.WeeklySummary;

/**
 * Planner Engine.
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
        int maxWeeks = 12;  // Cover full semester; ensures all assignments and exams are included
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
            // Include deadlines in a reasonable preparation window: from 12 weeks before
            // deadline until the deadline week. Avoids tasks too far ahead or past.
            LocalDate currentWeekStart = getWeekStart(LocalDate.now());
            List<Deadline> relevantDeadlines = deadlines.stream()
                    .filter(d -> {
                        if (d.getDueDate() == null) return false;
                        LocalDate deadlineWeekStart = getWeekStart(d.getDueDate());
                        return !weekStart.isAfter(deadlineWeekStart)  // not past deadline week
                                && !weekStart.isBefore(deadlineWeekStart.minusWeeks(12))  // not too early
                                && !weekStart.isBefore(currentWeekStart);  // not in the past
                    })
                    .toList();
            List<String> suggestions = geminiService.generateTaskSuggestionsForWeek(
                    relevantDeadlines, availableHours, feedback, weekStart, peakFocus, lowEnergy, restDays, typicalDuration);
            LocalDate today = LocalDate.now();
            Set<String> seen = new LinkedHashSet<>();
            for (String s : suggestions) {
                String[] parts = s.split("\\|");
                if (parts.length >= 4) {
                    try {
                        int day = Integer.parseInt(parts[3].trim());
                        int dayIndex = Math.max(0, Math.min(day - 1, 6));
                        LocalDate taskDate = weekStart.plusDays(dayIndex);
                        if (taskDate.isAfter(weekEnd)) continue;
                        if (taskDate.isBefore(today)) continue;  // never schedule for past dates
                        int hour = 9, min = 0;
                        if (parts.length >= 5) {
                            String[] hm = parts[4].trim().split(":");
                            if (hm.length >= 1) hour = Integer.parseInt(hm[0].trim());
                            if (hm.length >= 2) min = Integer.parseInt(hm[1].trim());
                        }
                        String dedupKey = parts[0] + "|" + parts[1] + "|" + taskDate + "|" + hour + ":" + min;
                        if (seen.contains(dedupKey)) continue;
                        seen.add(dedupKey);
                        LocalDateTime scheduledStart = taskDate.atTime(Math.min(23, Math.max(0, hour)), Math.min(59, Math.max(0, min)));
                        Deadline match = findMatchingDeadline(parts[0], parts[1], relevantDeadlines);
                        String diff = null;
                        Boolean ind = null;
                        if (match != null) {
                            if (isExamDeadline(match)) {
                                String dDiff = match.getDifficulty();
                                if (dDiff != null && dDiff.contains("%")) diff = dDiff;  // exam weight
                            } else {
                                diff = match.getDifficulty();
                                ind = match.getIsIndividual();
                            }
                        }
                        PlannerTask task = new PlannerTask(week.getId(), week.getUserId(),
                                parts[0], parts[1], parts[2], taskDate, scheduledStart, diff, ind);
                        tasks.add(task);
                    } catch (NumberFormatException ignored) {}
                }
            }
            fixOverlappingSessions(tasks);
            ensureAllDeadlinesRepresented(tasks, relevantDeadlines, week, today, restDays);
            spreadTasksAcrossDays(tasks, week, today, restDays);
            moveTasksOutOfLowEnergyTimes(tasks, peakFocus, lowEnergy, week, today);
            insertBreaksBetweenSessions(tasks, typicalDuration);
            fixOverlappingSessions(tasks);
        }

        if (tasks.isEmpty() && !deadlines.isEmpty()) {
            LocalDate today = LocalDate.now();
            LocalDate currentWeekStart = getWeekStart(LocalDate.now());
            List<LocalDate> availableDays = getAvailableDaysInWeek(week, today, restDays);
            if (availableDays.isEmpty()) availableDays = List.of(today.plusDays(1));  // fallback to tomorrow
            Set<String> seen = new LinkedHashSet<>();
            int dayIdx = 0;
            for (Deadline d : deadlines) {
                if (d.getDueDate() == null) continue;
                LocalDate deadlineWeekStart = getWeekStart(d.getDueDate());
                if (weekStart.isAfter(deadlineWeekStart)
                        || weekStart.isBefore(deadlineWeekStart.minusWeeks(12))
                        || weekStart.isBefore(currentWeekStart)) continue;
                String taskTitle = buildTaskTitle(d);
                String duration = "1 hour";
                if (isExamDeadline(d)) {
                    duration = "2 hours";
                }
                LocalDate taskDate = availableDays.get(dayIdx % availableDays.size());
                String dedupKey = taskTitle + "|" + d.getCourse() + "|" + taskDate;
                if (seen.contains(dedupKey)) { dayIdx++; continue; }
                seen.add(dedupKey);
                dayIdx++;
                LocalDateTime scheduledStart = taskDate.atTime(9, 0);
                String diff;
                Boolean ind;
                if (isExamDeadline(d)) {
                    String dDiff = d.getDifficulty();
                    diff = (dDiff != null && dDiff.contains("%")) ? dDiff : null;  // exam weight
                    ind = null;
                } else {
                    diff = d.getDifficulty();
                    ind = d.getIsIndividual();
                }
                PlannerTask task = new PlannerTask(week.getId(), week.getUserId(), taskTitle, d.getCourse(), duration, taskDate, scheduledStart, diff, ind);
                tasks.add(task);
            }
            spreadTasksAcrossDays(tasks, week, LocalDate.now(), restDays);
            moveTasksOutOfLowEnergyTimes(tasks, peakFocus, lowEnergy, week, LocalDate.now());
        }

        // Do NOT add generic tasks - only tasks from user-added deadlines
        return tasks;
    }

    /**
     * Spread tasks across available days so we use as many days as reasonable.
     * - No day has more than 3 sessions
     * - When we have many available days (e.g. Mon-Fri), use more of them instead of clustering on 1-2 days
     */
    private void spreadTasksAcrossDays(List<PlannerTask> tasks, PlannerWeek week, LocalDate today, List<String> restDays) {
        if (tasks.isEmpty()) return;
        LocalDate weekStart = week.getWeekStartDate();
        LocalDate weekEnd = week.getWeekEndDate();
        List<LocalDate> availableDays = new ArrayList<>();
        for (LocalDate d = weekStart; !d.isAfter(weekEnd); d = d.plusDays(1)) {
            if (d.isBefore(today)) continue;
            if (restDays != null) {
                String dayName = DAY_NAMES[d.getDayOfWeek().getValue() - 1];
                if (restDays.contains(dayName)) continue;
            }
            availableDays.add(d);
        }
        if (availableDays.isEmpty()) return;
        Map<LocalDate, List<PlannerTask>> byDate = new LinkedHashMap<>();
        for (PlannerTask t : tasks) {
            LocalDate d = t.getDueDate();
            if (d != null) byDate.computeIfAbsent(d, k -> new ArrayList<>()).add(t);
        }
        int maxPerDay = 3;
        int totalTasks = tasks.size();
        int targetDaysUsed = Math.min(availableDays.size(), Math.max(2, (totalTasks + 1) / 2));
        int targetPerDay = Math.max(1, totalTasks / targetDaysUsed);
        for (LocalDate day : new ArrayList<>(byDate.keySet())) {
            List<PlannerTask> dayTasks = byDate.get(day);
            while (dayTasks.size() > maxPerDay || (dayTasks.size() > targetPerDay && hasUnderusedDays(byDate, availableDays, targetPerDay))) {
                PlannerTask move = dayTasks.remove(dayTasks.size() - 1);
                LocalDate targetDay = findBestDayToMoveTo(byDate, availableDays, day, maxPerDay, targetPerDay);
                if (targetDay == null) break;
                move.setDueDate(targetDay);
                int hour = 9 + (byDate.getOrDefault(targetDay, List.of()).size() * 2);
                move.setScheduledStartTime(targetDay.atTime(Math.min(20, hour), 0));
                byDate.computeIfAbsent(targetDay, k -> new ArrayList<>()).add(move);
            }
        }
    }

    private boolean hasUnderusedDays(Map<LocalDate, List<PlannerTask>> byDate, List<LocalDate> availableDays, int targetPerDay) {
        long underused = availableDays.stream()
                .filter(d -> byDate.getOrDefault(d, List.of()).size() < targetPerDay)
                .count();
        return underused > 0;
    }

    private LocalDate findBestDayToMoveTo(Map<LocalDate, List<PlannerTask>> byDate, List<LocalDate> availableDays,
            LocalDate excludeDay, int maxPerDay, int targetPerDay) {
        for (LocalDate d : availableDays) {
            if (d.equals(excludeDay)) continue;
            int count = byDate.getOrDefault(d, List.of()).size();
            if (count < maxPerDay && count < targetPerDay) return d;
        }
        for (LocalDate d : availableDays) {
            if (d.equals(excludeDay)) continue;
            int count = byDate.getOrDefault(d, List.of()).size();
            if (count < maxPerDay) return d;
        }
        return null;
    }

    /**
     * Move tasks scheduled during low energy times to peak focus times.
     * Uses the same label format as focus profile: "Morning (9am-12pm)", etc.
     */
    private void moveTasksOutOfLowEnergyTimes(List<PlannerTask> tasks, List<String> peakFocus, List<String> lowEnergy,
            PlannerWeek week, LocalDate today) {
        if (tasks.isEmpty() || lowEnergy == null || lowEnergy.isEmpty()) return;
        Set<Integer> lowEnergyHours = parseTimeLabelsToHours(lowEnergy);
        Set<Integer> targetHours = (peakFocus != null && !peakFocus.isEmpty())
                ? parseTimeLabelsToHours(peakFocus)
                : Set.of(9, 10, 11, 14, 15, 16, 17, 18, 19, 20);  // default: avoid common low-energy slots
        targetHours = targetHours.stream().filter(h -> !lowEnergyHours.contains(h)).collect(java.util.stream.Collectors.toSet());
        if (targetHours.isEmpty()) return;
        for (PlannerTask t : tasks) {
            LocalDateTime start = t.getScheduledStartTime();
            if (start == null) continue;
            int hour = start.getHour();
            if (lowEnergyHours.contains(hour)) {
                Integer targetHour = targetHours.stream()
                        .min(Integer::compareTo)
                        .orElse(null);
                if (targetHour != null) {
                    t.setScheduledStartTime(t.getDueDate().atTime(targetHour, 0));
                }
            }
        }
    }

    /** Parse focus profile labels like "Morning (9am-12pm)" to set of hours (e.g. 9,10,11). */
    private Set<Integer> parseTimeLabelsToHours(List<String> labels) {
        Set<Integer> hours = new java.util.HashSet<>();
        for (String label : labels) {
            if (label == null) continue;
            if (label.contains("6am") && label.contains("9am")) { for (int h = 6; h < 9; h++) hours.add(h); }
            else if (label.contains("9am") && label.contains("12pm")) { for (int h = 9; h < 12; h++) hours.add(h); }
            else if (label.contains("12pm") && label.contains("5pm")) { for (int h = 12; h < 17; h++) hours.add(h); }
            else if (label.contains("5pm") && label.contains("9pm")) { for (int h = 17; h < 21; h++) hours.add(h); }
            else if (label.contains("9pm") && label.contains("1am")) { for (int h = 21; h < 24; h++) hours.add(h); hours.add(0); }
            else if (label.contains("1am") && label.contains("6am")) { for (int h = 1; h < 6; h++) hours.add(h); }
        }
        return hours;
    }

    private String buildTaskTitle(Deadline d) {
        String type = d.getType() != null ? d.getType().toLowerCase() : "";
        if (type.contains("exam") || type.contains("midterm") || type.contains("final") || type.contains("quiz")) {
            return "Prepare for " + d.getTitle();
        }
        return "Work on " + d.getTitle();
    }

    private boolean isExamDeadline(Deadline d) {
        String type = d.getType() != null ? d.getType().toLowerCase() : "";
        return type.contains("exam") || type.contains("midterm") || type.contains("final") || type.contains("quiz");
    }

    /** Find deadline that matches task title and course (for difficulty/isIndividual lookup). */
    private Deadline findMatchingDeadline(String taskTitle, String course, List<Deadline> deadlines) {
        if (deadlines == null || deadlines.isEmpty()) return null;
        String taskLower = taskTitle != null ? taskTitle.toLowerCase() : "";
        String courseLower = course != null ? course.toLowerCase() : "";
        for (Deadline d : deadlines) {
            String dTitle = d.getTitle() != null ? d.getTitle().toLowerCase() : "";
            String dCourse = d.getCourse() != null ? d.getCourse().toLowerCase() : "";
            if (!courseLower.equals(dCourse)) continue;
            if (dTitle.isEmpty()) return d;
            if (taskLower.contains(dTitle) || dTitle.contains(taskLower)) return d;
            String dPrefix = dTitle.length() > 10 ? dTitle.substring(0, 10) : dTitle;
            if ((taskLower.contains("prepare for ") || taskLower.contains("work on ")) && taskLower.contains(dPrefix)) return d;
        }
        return null;
    }

    /**
     * Insert rest breaks between back-to-back sessions based on user's typical study duration.
     * Users with shorter typical sessions (e.g. 45 min, 1 hr) get 15-min breaks; longer sessions get shorter breaks.
     */
    private void insertBreaksBetweenSessions(List<PlannerTask> tasks, String typicalDuration) {
        if (tasks.isEmpty() || typicalDuration == null || typicalDuration.isBlank()) return;
        int typicalMins = parseDurationToMinutes(typicalDuration);
        int breakMins = typicalMins <= 60 ? 15 : (typicalMins <= 90 ? 10 : 5);
        if (typicalMins >= 120) return;  // 2+ hours: user prefers long blocks, no forced breaks

        Map<LocalDate, List<PlannerTask>> byDate = new LinkedHashMap<>();
        for (PlannerTask t : tasks) {
            LocalDate d = t.getDueDate();
            if (d != null) byDate.computeIfAbsent(d, k -> new ArrayList<>()).add(t);
        }
        for (List<PlannerTask> dayTasks : byDate.values()) {
            dayTasks.sort(Comparator.comparing(PlannerTask::getScheduledStartTime, Comparator.nullsLast(Comparator.naturalOrder())));
            LocalDateTime lastEnd = null;
            for (PlannerTask t : dayTasks) {
                LocalDateTime start = t.getScheduledStartTime();
                if (start == null) continue;
                int minutes = parseDurationToMinutes(t.getDuration());
                if (lastEnd != null) {
                    long gapMins = java.time.Duration.between(lastEnd, start).toMinutes();
                    if (gapMins < 5) {  // back-to-back, insert break
                        start = lastEnd.plusMinutes(breakMins);
                    }
                }
                t.setScheduledStartTime(start);
                lastEnd = start.plusMinutes(minutes);
                if (lastEnd.toLocalTime().isAfter(LocalTime.of(23, 30))) {
                    lastEnd = t.getDueDate().atTime(23, 59);
                }
            }
        }
    }

    /**
     * Fix overlapping sessions by shifting later tasks to start after previous ones end.
     */
    private void fixOverlappingSessions(List<PlannerTask> tasks) {
        if (tasks.isEmpty()) return;
        Map<LocalDate, List<PlannerTask>> byDate = new LinkedHashMap<>();
        for (PlannerTask t : tasks) {
            LocalDate d = t.getDueDate();
            if (d != null) byDate.computeIfAbsent(d, k -> new ArrayList<>()).add(t);
        }
        for (List<PlannerTask> dayTasks : byDate.values()) {
            dayTasks.sort(Comparator.comparing(PlannerTask::getScheduledStartTime, Comparator.nullsLast(Comparator.naturalOrder())));
            LocalDateTime lastEnd = null;
            for (PlannerTask t : dayTasks) {
                LocalDateTime start = t.getScheduledStartTime();
                if (start == null) continue;
                int minutes = parseDurationToMinutes(t.getDuration());
                if (lastEnd != null && !start.isAfter(lastEnd)) {
                    start = lastEnd;
                    t.setScheduledStartTime(start);
                }
                lastEnd = start.plusMinutes(minutes);
                if (lastEnd.toLocalTime().isAfter(LocalTime.of(23, 30))) {
                    lastEnd = t.getDueDate().atTime(23, 59);
                }
            }
        }
    }

    private static final Pattern DURATION_HOURS = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*(?:hour|hours|h)", Pattern.CASE_INSENSITIVE);
    private static final Pattern DURATION_MINS = Pattern.compile("(\\d+)\\s*(?:minute|minutes|min|m)", Pattern.CASE_INSENSITIVE);

    private int parseDurationToMinutes(String duration) {
        if (duration == null || duration.isBlank()) return 60;
        int minutes = 0;
        Matcher h = DURATION_HOURS.matcher(duration);
        if (h.find()) minutes += (int) (Double.parseDouble(h.group(1)) * 60);
        Matcher m = DURATION_MINS.matcher(duration);
        if (m.find()) minutes += Integer.parseInt(m.group(1));
        return minutes > 0 ? minutes : 60;
    }

    /**
     * Add a task for any relevant deadline that has no task yet.
     * Uses available days in the week so ALL deadlines get a task.
     */
    private void ensureAllDeadlinesRepresented(List<PlannerTask> tasks, List<Deadline> relevantDeadlines,
            PlannerWeek week, LocalDate today, List<String> restDays) {
        if (relevantDeadlines == null || relevantDeadlines.isEmpty()) return;
        List<LocalDate> availableDays = getAvailableDaysInWeek(week, today, restDays);
        if (availableDays.isEmpty()) availableDays = List.of(today);
        Map<LocalDate, Integer> nextHourByDate = new LinkedHashMap<>();
        for (LocalDate d : availableDays) nextHourByDate.put(d, 9);
        int dayIdx = 0;
        for (Deadline d : relevantDeadlines) {
            String dTitle = d.getTitle() != null ? d.getTitle() : "";
            boolean covered = false;
            for (PlannerTask t : tasks) {
                String tTitle = t.getTitle() != null ? t.getTitle() : "";
                if (tTitle.contains(dTitle) || (dTitle.length() > 3 && tTitle.contains(dTitle.substring(0, Math.min(10, dTitle.length()))))) {
                    covered = true;
                    break;
                }
            }
            if (covered) continue;
            String taskTitle = buildTaskTitle(d);
            String duration = "1 hour";
            if (isExamDeadline(d)) {
                duration = "2 hours";
            }
            LocalDate taskDate = availableDays.get(dayIdx % availableDays.size());
            int hour = nextHourByDate.get(taskDate);
            if (hour >= 21) {
                dayIdx++;
                taskDate = availableDays.get(dayIdx % availableDays.size());
                hour = 9;
            }
            LocalDateTime scheduledStart = taskDate.atTime(Math.min(22, hour), 0);
            String diff;
            Boolean ind;
            if (isExamDeadline(d)) {
                String dDiff = d.getDifficulty();
                diff = (dDiff != null && dDiff.contains("%")) ? dDiff : null;
                ind = null;
            } else {
                diff = d.getDifficulty();
                ind = d.getIsIndividual();
            }
            PlannerTask task = new PlannerTask(week.getId(), week.getUserId(), taskTitle, d.getCourse(), duration, taskDate, scheduledStart, diff, ind);
            tasks.add(task);
            nextHourByDate.put(taskDate, hour + 2);
        }
        fixOverlappingSessions(tasks);
    }

    /** Get week days that are >= today and not rest days. */
    private List<LocalDate> getAvailableDaysInWeek(PlannerWeek week, LocalDate today, List<String> restDays) {
        LocalDate weekStart = week.getWeekStartDate();
        LocalDate weekEnd = week.getWeekEndDate();
        List<LocalDate> out = new ArrayList<>();
        for (LocalDate d = weekStart; !d.isAfter(weekEnd); d = d.plusDays(1)) {
            if (d.isBefore(today)) continue;
            if (restDays != null) {
                String dayName = DAY_NAMES[d.getDayOfWeek().getValue() - 1];
                if (restDays.contains(dayName)) continue;
            }
            out.add(d);
        }
        return out;
    }

}
