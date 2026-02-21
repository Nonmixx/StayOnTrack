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
import com.stayontrack.model.Deadline;
import com.stayontrack.model.PlannerTask;
import com.stayontrack.model.PlannerWeek;
import com.stayontrack.model.Task;
import com.stayontrack.model.WeeklyCheckIn;

@Service
public class FirestoreService {

    private static final String TASKS_COLLECTION = "tasks";
    private static final String DEADLINES_COLLECTION = "deadlines";
    private static final String WEEKLY_CHECK_INS_COLLECTION = "weeklyCheckIns";
    private static final String PLANNER_WEEKS_COLLECTION = "plannerWeeks";
    private static final String PLANNER_TASKS_COLLECTION = "plannerTasks";

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
        map.put("status", t.getStatus());
        if (t.getDueDate() != null) {
            map.put("dueDate", Timestamp.of(java.sql.Timestamp.from(
                    t.getDueDate().atStartOfDay(ZoneId.systemDefault()).toInstant())));
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
        t.setStatus(doc.getString("status"));
        Timestamp ts = doc.getTimestamp("dueDate");
        if (ts != null) {
            t.setDueDate(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()).toLocalDate());
        }
        ts = doc.getTimestamp("createdAt");
        if (ts != null) {
            t.setCreatedAt(LocalDateTime.ofInstant(ts.toDate().toInstant(), ZoneId.systemDefault()));
        }
        return t;
    }
}
