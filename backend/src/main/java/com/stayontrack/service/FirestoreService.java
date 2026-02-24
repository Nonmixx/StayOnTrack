package com.stayontrack.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import com.stayontrack.model.Assignment;
import com.stayontrack.model.Deadline;
import com.stayontrack.model.Exam;
import com.stayontrack.model.FocusProfile;
import com.stayontrack.model.PlannerTask;
import com.stayontrack.model.PlannerWeek;
import com.stayontrack.model.Semester;
import com.stayontrack.model.Task;
import com.stayontrack.model.WeeklyCheckIn;

@Service
public class FirestoreService {

    private static final String TASKS_COLLECTION = "tasks";
    private static final String DEADLINES_COLLECTION = "deadlines";
    private static final String WEEKLY_CHECK_INS_COLLECTION = "weeklyCheckIns";
    private static final String PLANNER_WEEKS_COLLECTION = "plannerWeeks";
    private static final String PLANNER_TASKS_COLLECTION = "plannerTasks";
    private static final String SEMESTERS_COLLECTION = "semesters";
    private static final String EXAMS_COLLECTION = "exams";
    private static final String ASSIGNMENTS_COLLECTION = "assignments";
    private static final String FOCUS_PROFILES_COLLECTION = "focusProfiles";

    private Firestore getFirestore() {
        return FirestoreClient.getFirestore();
    }

    // ==================== TASKS ====================

    public Task createTask(Task task) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = taskToMap(task);
        DocumentReference docRef = db.collection(TASKS_COLLECTION).add(data).get();
        task.setId(docRef.getId());
        return task;
    }

    public List<Task> getTasksByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(TASKS_COLLECTION)
                .whereEqualTo("userId", userId)
                .orderBy("dueDate", Query.Direction.ASCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<Task> tasks = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            Task task = mapToTask(doc);
            if (task != null) tasks.add(task);
        }
        return tasks;
    }

    public List<Task> getTasksForDate(String userId, LocalDate date) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Instant startOfDay = date.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant endOfDay = date.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
        Query query = db.collection(TASKS_COLLECTION)
                .whereEqualTo("userId", userId)
                .whereGreaterThanOrEqualTo("dueDate", Timestamp.of(java.sql.Timestamp.from(startOfDay)))
                .whereLessThan("dueDate", Timestamp.of(java.sql.Timestamp.from(endOfDay)))
                .orderBy("dueDate", Query.Direction.ASCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<Task> tasks = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            Task task = mapToTask(doc);
            if (task != null) tasks.add(task);
        }
        return tasks;
    }

    public Task updateTask(String taskId, Task task) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(TASKS_COLLECTION).document(taskId);
        Map<String, Object> updates = new HashMap<>();
        if (task.getTitle() != null) updates.put("title", task.getTitle());
        if (task.getCourse() != null) updates.put("course", task.getCourse());
        if (task.getDuration() != null) updates.put("duration", task.getDuration());
        updates.put("completed", task.isCompleted());
        if (task.getDueDate() != null) {
            updates.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    task.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        docRef.update(updates).get();
        task.setId(taskId);
        return task;
    }

    public void deleteTask(String taskId) throws ExecutionException, InterruptedException {
        getFirestore().collection(TASKS_COLLECTION).document(taskId).delete().get();
    }

    // ==================== DEADLINES ====================

    public Deadline createDeadline(Deadline deadline) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = deadlineToMap(deadline);
        DocumentReference docRef = db.collection(DEADLINES_COLLECTION).add(data).get();
        deadline.setId(docRef.getId());
        return deadline;
    }

    public List<Deadline> getDeadlinesByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(DEADLINES_COLLECTION)
                .whereEqualTo("userId", userId)
                .orderBy("dueDate", Query.Direction.ASCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<Deadline> deadlines = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            Deadline d = mapToDeadline(doc);
            if (d != null) deadlines.add(d);
        }
        return deadlines;
    }

    public Deadline updateDeadline(String deadlineId, Deadline deadline) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(DEADLINES_COLLECTION).document(deadlineId);
        Map<String, Object> updates = new HashMap<>();
        if (deadline.getTitle() != null) updates.put("title", deadline.getTitle());
        if (deadline.getCourse() != null) updates.put("course", deadline.getCourse());
        if (deadline.getType() != null) updates.put("type", deadline.getType());
        if (deadline.getDifficulty() != null) updates.put("difficulty", deadline.getDifficulty());
        if (deadline.getIsIndividual() != null) updates.put("isIndividual", deadline.getIsIndividual());
        if (deadline.getDueDate() != null) {
            updates.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    deadline.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        docRef.update(updates).get();
        deadline.setId(deadlineId);
        return deadline;
    }

    public void deleteDeadline(String deadlineId) throws ExecutionException, InterruptedException {
        getFirestore().collection(DEADLINES_COLLECTION).document(deadlineId).delete().get();
    }

    // ==================== WEEKLY CHECK-INS ====================

    public WeeklyCheckIn createWeeklyCheckIn(WeeklyCheckIn checkIn) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = weeklyCheckInToMap(checkIn);
        DocumentReference docRef = db.collection(WEEKLY_CHECK_INS_COLLECTION).add(data).get();
        checkIn.setId(docRef.getId());
        return checkIn;
    }

    public List<WeeklyCheckIn> getWeeklyCheckInsByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(WEEKLY_CHECK_INS_COLLECTION)
                .whereEqualTo("userId", userId)
                .orderBy("createdAt", Query.Direction.DESCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<WeeklyCheckIn> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            WeeklyCheckIn w = mapToWeeklyCheckIn(doc);
            if (w != null) list.add(w);
        }
        return list;
    }

    // ==================== PLANNER WEEKS ====================

    public PlannerWeek createPlannerWeek(PlannerWeek week) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = plannerWeekToMap(week);
        DocumentReference docRef = db.collection(PLANNER_WEEKS_COLLECTION).add(data).get();
        week.setId(docRef.getId());
        return week;
    }

    public PlannerWeek getPlannerWeekByDate(String userId, LocalDate weekStartDate) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Instant start = weekStartDate.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Query query = db.collection(PLANNER_WEEKS_COLLECTION)
                .whereEqualTo("userId", userId)
                .whereEqualTo("weekStartDate", Timestamp.of(java.sql.Timestamp.from(start)));
        QuerySnapshot snapshot = query.get().get();
        if (snapshot.isEmpty()) return null;
        return mapToPlannerWeek(snapshot.getDocuments().get(0));
    }

    public List<PlannerWeek> getPlannerWeeksByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(PLANNER_WEEKS_COLLECTION)
                .whereEqualTo("userId", userId)
                .orderBy("weekStartDate", Query.Direction.ASCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<PlannerWeek> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            PlannerWeek w = mapToPlannerWeek(doc);
            if (w != null) list.add(w);
        }
        return list;
    }

    public void deletePlannerWeek(String weekId) throws ExecutionException, InterruptedException {
        getFirestore().collection(PLANNER_WEEKS_COLLECTION).document(weekId).delete().get();
    }

    // ==================== PLANNER TASKS ====================

    public PlannerTask createPlannerTask(PlannerTask task) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = plannerTaskToMap(task);
        DocumentReference docRef = db.collection(PLANNER_TASKS_COLLECTION).add(data).get();
        task.setId(docRef.getId());
        return task;
    }

    public List<PlannerTask> getPlannerTasksByWeekId(String plannerWeekId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(PLANNER_TASKS_COLLECTION)
                .whereEqualTo("plannerWeekId", plannerWeekId)
                .orderBy("dueDate", Query.Direction.ASCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<PlannerTask> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            PlannerTask t = mapToPlannerTask(doc);
            if (t != null) list.add(t);
        }
        return list;
    }

    public List<PlannerTask> getPlannerTasksForDate(String userId, LocalDate date) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Instant startOfDay = date.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant endOfDay = date.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
        Query query = db.collection(PLANNER_TASKS_COLLECTION)
                .whereEqualTo("userId", userId)
                .whereGreaterThanOrEqualTo("dueDate", Timestamp.of(java.sql.Timestamp.from(startOfDay)))
                .whereLessThan("dueDate", Timestamp.of(java.sql.Timestamp.from(endOfDay)))
                .orderBy("dueDate", Query.Direction.ASCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<PlannerTask> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            PlannerTask t = mapToPlannerTask(doc);
            if (t != null) list.add(t);
        }
        return list;
    }

    public List<PlannerTask> getPlannerTasksForWeek(String userId, LocalDate weekStartDate) throws ExecutionException, InterruptedException {
        PlannerWeek week = getPlannerWeekByDate(userId, weekStartDate);
        if (week == null) return List.of();
        return getPlannerTasksByWeekId(week.getId());
    }

    public int getPlannerTaskCountForMonth(String userId, int year, int month) throws ExecutionException, InterruptedException {
        LocalDate monthStart = LocalDate.of(year, month, 1);
        LocalDate monthEnd = monthStart.plusMonths(1);
        Instant start = monthStart.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = monthEnd.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Firestore db = getFirestore();
        Query query = db.collection(PLANNER_TASKS_COLLECTION)
                .whereEqualTo("userId", userId)
                .whereGreaterThanOrEqualTo("dueDate", Timestamp.of(java.sql.Timestamp.from(start)))
                .whereLessThan("dueDate", Timestamp.of(java.sql.Timestamp.from(end)));
        return (int) query.get().get().size();
    }

    public PlannerTask updatePlannerTask(String taskId, PlannerTask task) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(PLANNER_TASKS_COLLECTION).document(taskId);
        Map<String, Object> updates = new HashMap<>();
        if (task.getTitle() != null) updates.put("title", task.getTitle());
        if (task.getCourse() != null) updates.put("course", task.getCourse());
        if (task.getDuration() != null) updates.put("duration", task.getDuration());
        updates.put("completed", task.isCompleted());
        if (task.getStatus() != null) updates.put("status", task.getStatus());
        if (task.getDueDate() != null) {
            updates.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    task.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        docRef.update(updates).get();
        task.setId(taskId);
        return task;
    }

    public void deletePlannerTasksByWeekId(String plannerWeekId) throws ExecutionException, InterruptedException {
        List<PlannerTask> tasks = getPlannerTasksByWeekId(plannerWeekId);
        Firestore db = getFirestore();
        for (PlannerTask t : tasks) {
            db.collection(PLANNER_TASKS_COLLECTION).document(t.getId()).delete().get();
        }
    }

    // ==================== SEMESTERS ====================

    public Semester createSemester(Semester semester) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = semesterToMap(semester);
        DocumentReference docRef = db.collection(SEMESTERS_COLLECTION).add(data).get();
        semester.setId(docRef.getId());
        return semester;
    }

    public List<Semester> getSemestersByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(SEMESTERS_COLLECTION).whereEqualTo("userId", userId);
        QuerySnapshot snapshot = query.get().get();
        List<Semester> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            Semester s = mapToSemester(doc);
            if (s != null) list.add(s);
        }
        list.sort((a, b) -> {
            if (a.getCreatedAt() == null || b.getCreatedAt() == null) return 0;
            return b.getCreatedAt().compareTo(a.getCreatedAt());
        });
        return list;
    }

    public Semester updateSemester(String semesterId, Semester semester) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(SEMESTERS_COLLECTION).document(semesterId);
        Map<String, Object> updates = new HashMap<>();
        if (semester.getSemesterName() != null) updates.put("semesterName", semester.getSemesterName());
        if (semester.getStartDate() != null) updates.put("startDate", semester.getStartDate());
        if (semester.getEndDate() != null) updates.put("endDate", semester.getEndDate());
        if (semester.getStudyMode() != null) updates.put("studyMode", semester.getStudyMode());
        if (semester.getRestDays() != null) updates.put("restDays", semester.getRestDays());
        docRef.update(updates).get();
        semester.setId(semesterId);
        return semester;
    }

    public void deleteSemester(String semesterId) throws ExecutionException, InterruptedException {
        getFirestore().collection(SEMESTERS_COLLECTION).document(semesterId).delete().get();
    }

    // ==================== EXAMS ====================

    public Exam createExam(Exam exam) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = examToMap(exam);
        DocumentReference docRef = db.collection(EXAMS_COLLECTION).add(data).get();
        exam.setId(docRef.getId());
        return exam;
    }

    public List<Exam> getExamsByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(EXAMS_COLLECTION)
                .whereEqualTo("userId", userId)
                .orderBy("createdAt", Query.Direction.DESCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<Exam> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            Exam e = mapToExam(doc);
            if (e != null) list.add(e);
        }
        return list;
    }

    public Exam updateExam(String examId, Exam exam) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(EXAMS_COLLECTION).document(examId);
        Map<String, Object> updates = new HashMap<>();
        if (exam.getCourseName() != null) updates.put("courseName", exam.getCourseName());
        if (exam.getExamType() != null) updates.put("examType", exam.getExamType());
        if (exam.getDate() != null) updates.put("date", exam.getDate());
        if (exam.getWeightPercentage() != null) updates.put("weightPercentage", exam.getWeightPercentage());
        docRef.update(updates).get();
        exam.setId(examId);
        return exam;
    }

    public void deleteExam(String examId) throws ExecutionException, InterruptedException {
        getFirestore().collection(EXAMS_COLLECTION).document(examId).delete().get();
    }

    // ==================== ASSIGNMENTS ====================

    public Assignment createAssignment(Assignment assignment) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = assignmentToMap(assignment);
        DocumentReference docRef = db.collection(ASSIGNMENTS_COLLECTION).add(data).get();
        assignment.setId(docRef.getId());
        return assignment;
    }

    public List<Assignment> getAssignmentsByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(ASSIGNMENTS_COLLECTION)
                .whereEqualTo("userId", userId)
                .orderBy("createdAt", Query.Direction.DESCENDING);
        QuerySnapshot snapshot = query.get().get();
        List<Assignment> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            Assignment a = mapToAssignment(doc);
            if (a != null) list.add(a);
        }
        return list;
    }

    public Assignment updateAssignment(String assignmentId, Assignment assignment) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(ASSIGNMENTS_COLLECTION).document(assignmentId);
        Map<String, Object> updates = new HashMap<>();
        if (assignment.getCourseName() != null) updates.put("courseName", assignment.getCourseName());
        if (assignment.getAssignmentName() != null) updates.put("assignmentName", assignment.getAssignmentName());
        if (assignment.getDeadline() != null) updates.put("deadline", assignment.getDeadline());
        if (assignment.getDifficulty() != null) updates.put("difficulty", assignment.getDifficulty());
        if (assignment.getType() != null) updates.put("type", assignment.getType());
        docRef.update(updates).get();
        assignment.setId(assignmentId);
        return assignment;
    }

    public void deleteAssignment(String assignmentId) throws ExecutionException, InterruptedException {
        getFirestore().collection(ASSIGNMENTS_COLLECTION).document(assignmentId).delete().get();
    }

    // ==================== FOCUS PROFILES ====================

    public FocusProfile createFocusProfile(FocusProfile profile) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Map<String, Object> data = focusProfileToMap(profile);
        DocumentReference docRef = db.collection(FOCUS_PROFILES_COLLECTION).add(data).get();
        profile.setId(docRef.getId());
        return profile;
    }

    public List<FocusProfile> getFocusProfilesByUserId(String userId) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        Query query = db.collection(FOCUS_PROFILES_COLLECTION).whereEqualTo("userId", userId);
        QuerySnapshot snapshot = query.get().get();
        List<FocusProfile> list = new ArrayList<>();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            FocusProfile f = mapToFocusProfile(doc);
            if (f != null) list.add(f);
        }
        list.sort((a, b) -> {
            if (a.getCreatedAt() == null || b.getCreatedAt() == null) return 0;
            return b.getCreatedAt().compareTo(a.getCreatedAt());
        });
        return list;
    }

    public FocusProfile updateFocusProfile(String profileId, FocusProfile profile) throws ExecutionException, InterruptedException {
        Firestore db = getFirestore();
        DocumentReference docRef = db.collection(FOCUS_PROFILES_COLLECTION).document(profileId);
        Map<String, Object> updates = new HashMap<>();
        if (profile.getPeakFocusTimes() != null) updates.put("peakFocusTimes", profile.getPeakFocusTimes());
        if (profile.getLowEnergyTimes() != null) updates.put("lowEnergyTimes", profile.getLowEnergyTimes());
        if (profile.getTypicalStudyDuration() != null) updates.put("typicalStudyDuration", profile.getTypicalStudyDuration());
        docRef.update(updates).get();
        profile.setId(profileId);
        return profile;
    }

    public void deleteFocusProfile(String profileId) throws ExecutionException, InterruptedException {
        getFirestore().collection(FOCUS_PROFILES_COLLECTION).document(profileId).delete().get();
    }

    // ==================== HELPERS ====================

    private Map<String, Object> taskToMap(Task task) {
        Map<String, Object> map = new HashMap<>();
        map.put("title", task.getTitle());
        map.put("course", task.getCourse());
        map.put("duration", task.getDuration());
        map.put("completed", task.isCompleted());
        map.put("userId", task.getUserId());
        if (task.getDueDate() != null) {
            map.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    task.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        if (task.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    task.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private Task mapToTask(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        Task task = new Task();
        task.setId(doc.getId());
        task.setTitle(doc.getString("title"));
        task.setCourse(doc.getString("course"));
        task.setDuration(doc.getString("duration"));
        task.setCompleted(Boolean.TRUE.equals(doc.getBoolean("completed")));
        task.setUserId(doc.getString("userId"));
        Timestamp ts = doc.getTimestamp("dueDate");
        if (ts != null) {
            task.setDueDate(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()).toLocalDate());
        }
        ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            task.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return task;
    }

    private Map<String, Object> deadlineToMap(Deadline d) {
        Map<String, Object> map = new HashMap<>();
        map.put("title", d.getTitle());
        map.put("course", d.getCourse());
        map.put("type", d.getType());
        map.put("userId", d.getUserId());
        if (d.getDifficulty() != null) map.put("difficulty", d.getDifficulty());
        if (d.getIsIndividual() != null) map.put("isIndividual", d.getIsIndividual());
        if (d.getDueDate() != null) {
            map.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    d.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        if (d.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    d.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private Deadline mapToDeadline(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        Deadline d = new Deadline();
        d.setId(doc.getId());
        d.setTitle(doc.getString("title"));
        d.setCourse(doc.getString("course"));
        d.setType(doc.getString("type"));
        d.setUserId(doc.getString("userId"));
        d.setDifficulty(doc.getString("difficulty"));
        Boolean ind = doc.getBoolean("isIndividual");
        d.setIsIndividual(ind != null ? ind : Boolean.TRUE);
        Timestamp ts = doc.getTimestamp("dueDate");
        if (ts != null) {
            d.setDueDate(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()).toLocalDate());
        }
        ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            d.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return d;
    }

    private Map<String, Object> weeklyCheckInToMap(WeeklyCheckIn w) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", w.getUserId());
        map.put("feedback", w.getFeedback());
        map.put("availableStudyHoursNextWeek", w.getAvailableStudyHoursNextWeek());
        if (w.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    w.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private WeeklyCheckIn mapToWeeklyCheckIn(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        WeeklyCheckIn w = new WeeklyCheckIn();
        w.setId(doc.getId());
        w.setUserId(doc.getString("userId"));
        w.setFeedback(doc.getString("feedback"));
        Long hours = doc.getLong("availableStudyHoursNextWeek");
        w.setAvailableStudyHoursNextWeek(hours != null ? hours.intValue() : 0);
        Timestamp ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            w.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return w;
    }

    private Map<String, Object> plannerWeekToMap(PlannerWeek w) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", w.getUserId());
        map.put("availableHours", w.getAvailableHours());
        if (w.getWeekStartDate() != null) {
            map.put("weekStartDate", Timestamp.of(java.sql.Timestamp.from(
                    w.getWeekStartDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        if (w.getWeekEndDate() != null) {
            map.put("weekEndDate", Timestamp.of(java.sql.Timestamp.from(
                    w.getWeekEndDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        if (w.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    w.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private PlannerWeek mapToPlannerWeek(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        PlannerWeek w = new PlannerWeek();
        w.setId(doc.getId());
        w.setUserId(doc.getString("userId"));
        Long hours = doc.getLong("availableHours");
        w.setAvailableHours(hours != null ? hours.intValue() : 0);
        Timestamp ts = doc.getTimestamp("weekStartDate");
        if (ts != null) {
            w.setWeekStartDate(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()).toLocalDate());
        }
        ts = doc.getTimestamp("weekEndDate");
        if (ts != null) {
            w.setWeekEndDate(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()).toLocalDate());
        }
        ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            w.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return w;
    }

    private Map<String, Object> plannerTaskToMap(PlannerTask t) {
        Map<String, Object> map = new HashMap<>();
        map.put("plannerWeekId", t.getPlannerWeekId());
        map.put("userId", t.getUserId());
        map.put("title", t.getTitle());
        map.put("course", t.getCourse());
        map.put("duration", t.getDuration());
        map.put("completed", t.isCompleted());
        map.put("difficulty", t.getDifficulty());
        if (t.getIsIndividual() != null) map.put("isIndividual", t.getIsIndividual());
        map.put("status", t.getStatus());
        if (t.getDueDate() != null) {
            map.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    t.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
        }
        if (t.getScheduledStartTime() != null) {
            map.put("scheduledStartTime", Timestamp.of(java.sql.Timestamp.from(
                    t.getScheduledStartTime().atZone(ZoneId.systemDefault()).toInstant())));
        }
        if (t.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    t.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private PlannerTask mapToPlannerTask(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        PlannerTask t = new PlannerTask();
        t.setId(doc.getId());
        t.setPlannerWeekId(doc.getString("plannerWeekId"));
        t.setUserId(doc.getString("userId"));
        t.setTitle(doc.getString("title"));
        t.setCourse(doc.getString("course"));
        t.setDuration(doc.getString("duration"));
        t.setCompleted(Boolean.TRUE.equals(doc.getBoolean("completed")));
        t.setDifficulty(doc.getString("difficulty"));
        Boolean ind = doc.getBoolean("isIndividual");
        t.setIsIndividual(ind != null ? ind : Boolean.TRUE);
        t.setStatus(doc.getString("status"));
        Timestamp ts = doc.getTimestamp("dueDate");
        if (ts != null) {
            t.setDueDate(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()).toLocalDate());
        }
        ts = doc.getTimestamp("scheduledStartTime");
        if (ts != null) {
            t.setScheduledStartTime(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            t.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return t;
    }

    private Map<String, Object> semesterToMap(Semester s) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", s.getUserId());
        if (s.getSemesterName() != null) map.put("semesterName", s.getSemesterName());
        if (s.getStartDate() != null) map.put("startDate", s.getStartDate());
        if (s.getEndDate() != null) map.put("endDate", s.getEndDate());
        if (s.getStudyMode() != null) map.put("studyMode", s.getStudyMode());
        if (s.getRestDays() != null) map.put("restDays", s.getRestDays());
        if (s.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    s.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private Semester mapToSemester(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        Semester s = new Semester();
        s.setId(doc.getId());
        s.setUserId(doc.getString("userId"));
        s.setSemesterName(doc.getString("semesterName"));
        s.setStartDate(doc.getString("startDate"));
        s.setEndDate(doc.getString("endDate"));
        s.setStudyMode(doc.getString("studyMode"));
        Object restDaysObj = doc.get("restDays");
        List<String> restDays = restDaysObj != null ? (List<String>) restDaysObj : null;
        s.setRestDays(restDays);
        Timestamp ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            s.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return s;
    }

    private Map<String, Object> examToMap(Exam e) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", e.getUserId());
        if (e.getCourseName() != null) map.put("courseName", e.getCourseName());
        if (e.getExamType() != null) map.put("examType", e.getExamType());
        if (e.getDate() != null) map.put("date", e.getDate());
        if (e.getWeightPercentage() != null) map.put("weightPercentage", e.getWeightPercentage());
        if (e.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    e.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private Exam mapToExam(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        Exam e = new Exam();
        e.setId(doc.getId());
        e.setUserId(doc.getString("userId"));
        e.setCourseName(doc.getString("courseName"));
        e.setExamType(doc.getString("examType"));
        e.setDate(doc.getString("date"));
        Double weight = doc.getDouble("weightPercentage");
        e.setWeightPercentage(weight);
        Timestamp ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            e.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return e;
    }

    private Map<String, Object> assignmentToMap(Assignment a) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", a.getUserId());
        if (a.getCourseName() != null) map.put("courseName", a.getCourseName());
        if (a.getAssignmentName() != null) map.put("assignmentName", a.getAssignmentName());
        if (a.getDeadline() != null) map.put("deadline", a.getDeadline());
        if (a.getDifficulty() != null) map.put("difficulty", a.getDifficulty());
        if (a.getType() != null) map.put("type", a.getType());
        if (a.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    a.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private Assignment mapToAssignment(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        Assignment a = new Assignment();
        a.setId(doc.getId());
        a.setUserId(doc.getString("userId"));
        a.setCourseName(doc.getString("courseName"));
        a.setAssignmentName(doc.getString("assignmentName"));
        a.setDeadline(doc.getString("deadline"));
        a.setDifficulty(doc.getString("difficulty"));
        a.setType(doc.getString("type"));
        Timestamp ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            a.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return a;
    }

    private Map<String, Object> focusProfileToMap(FocusProfile f) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", f.getUserId());
        if (f.getPeakFocusTimes() != null) map.put("peakFocusTimes", f.getPeakFocusTimes());
        if (f.getLowEnergyTimes() != null) map.put("lowEnergyTimes", f.getLowEnergyTimes());
        if (f.getTypicalStudyDuration() != null) map.put("typicalStudyDuration", f.getTypicalStudyDuration());
        if (f.getCreatedAt() != null) {
            map.put("createdAt", Timestamp.of(java.sql.Timestamp.from(
                    f.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant())));
        }
        return map;
    }

    private FocusProfile mapToFocusProfile(DocumentSnapshot doc) {
        if (doc == null || !doc.exists()) return null;
        FocusProfile f = new FocusProfile();
        f.setId(doc.getId());
        f.setUserId(doc.getString("userId"));
        Object peakObj = doc.get("peakFocusTimes");
        List<String> peak = peakObj != null ? (List<String>) peakObj : null;
        f.setPeakFocusTimes(peak);
        Object lowObj = doc.get("lowEnergyTimes");
        List<String> low = lowObj != null ? (List<String>) lowObj : null;
        f.setLowEnergyTimes(low);
        f.setTypicalStudyDuration(doc.getString("typicalStudyDuration"));
        Timestamp ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            f.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return f;
    }
}
