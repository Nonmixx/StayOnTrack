package com.stayontrack.service;

import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class GroupService {

    @Autowired
    private AIService aiService;

    // ── FIX: was `private final Firestore db = FirestoreClient.getFirestore();`
    //    That runs at field-init time, BEFORE FirebaseConfig @PostConstruct,
    //    so Firebase isn't initialized yet → falls back to Vertex AI gRPC → quota error.
    //    Solution: fetch db lazily inside each method call instead. ──
    private Firestore getDb() {
        return FirestoreClient.getFirestore();
    }

    public String createGroupAssignment(Map<String, Object> body) {
        System.out.println("✅ createGroupAssignment called");
        System.out.println("📦 Body keys: " + body.keySet());

        try {
            Firestore db = getDb();

            DocumentReference docRef = db.collection("groups").document();
            String assignmentId = docRef.getId();
            System.out.println("📝 assignmentId: " + assignmentId);

            List<Map<String, Object>> members =
                (List<Map<String, Object>>) body.get("members");

            List<String> memberInitials = members.stream()
                .map(m -> {
                    String name = (String) m.get("name");
                    return (name != null && !name.isEmpty())
                        ? String.valueOf(name.charAt(0)).toUpperCase() : "?";
                })
                .collect(Collectors.toList());

            Map<String, Object> groupData = new HashMap<>(body);
            groupData.put("createdAt", FieldValue.serverTimestamp());
            groupData.put("memberInitials", memberInitials);
            docRef.set(groupData).get();
            System.out.println("✅ Group document saved");

            for (Map<String, Object> member : members) {
                db.collection("groups").document(assignmentId)
                  .collection("members").add(member).get();
            }
            System.out.println("✅ Members saved (" + members.size() + ")");

            String brief = (String) body.get("brief");
            System.out.println("📋 Brief length: " + (brief != null ? brief.length() : 0));
            List<Map<String, Object>> distribution = aiService.generateFullPlan(brief, members);
            System.out.println("✅ AI distribution for " + distribution.size() + " members");
            if (distribution.isEmpty()) {
                throw new RuntimeException("AI did not generate tasks/distribution. Check Gemini API quota/key.");
            }

            List<Map<String, Object>> tasks = flattenTasksFromDistribution(distribution);
            normalizeDependenciesWithTaskIds(tasks, distribution);

            if (tasks.size() < 4) {
                System.out.println("⚠️ createGroupAssignment generated only " + tasks.size() + " unique tasks. Retrying with extract+distribute fallback...");

                List<Map<String, Object>> recoveredTasks = aiService.extractTasksAiOnly(brief, members);
                List<Map<String, Object>> recoveredDistribution = aiService.distributeTasks(recoveredTasks, members);
                List<Map<String, Object>> recoveredFlatTasks = flattenTasksFromDistribution(recoveredDistribution);
                normalizeDependenciesWithTaskIds(recoveredFlatTasks, recoveredDistribution);

                if (recoveredFlatTasks.size() > tasks.size()) {
                    System.out.println("✅ Recovery produced " + recoveredFlatTasks.size() + " tasks. Using recovered result.");
                    tasks = recoveredFlatTasks;
                    distribution = recoveredDistribution;
                } else {
                    System.out.println("⚠️ Recovery did not improve task count. Keeping original result.");
                }
            }

            System.out.println("✅ Flattened " + tasks.size() + " tasks from mega-prompt distribution");
            if (tasks.isEmpty()) {
                throw new RuntimeException("AI returned distribution but no tasks.");
            }

            for (Map<String, Object> task : tasks) {
                db.collection("groupTasks").document(assignmentId)
                    .collection("tasks").add(task).get();
            }
            System.out.println("✅ Tasks saved to Firestore");

            saveDistribution(db, assignmentId, distribution);
            System.out.println("✅ Distribution saved");

            return assignmentId;

        } catch (Exception e) {
            System.err.println("❌ Error in createGroupAssignment: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to create group assignment", e);
        }
    }

    public List<Map<String, Object>> getGroupsByUser(String userId) {
        try {
            Firestore db = getDb();
            QuerySnapshot snapshot = db.collection("groups")
                .whereEqualTo("userId", userId)
                .get().get();
            return snapshot.getDocuments().stream()
                .map(doc -> {
                    Map<String, Object> data = new HashMap<>(doc.getData());
                    data.put("id", doc.getId());
                    return data;
                })
                .collect(Collectors.toList());
        } catch (Exception e) {
            System.err.println("❌ getGroupsByUser error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> getTasks(String assignmentId) {
        try {
            Firestore db = getDb();
            QuerySnapshot snapshot = db.collection("groupTasks")
                .document(assignmentId)
                .collection("tasks")
                .get().get();
            List<Map<String, Object>> tasks = snapshot.getDocuments().stream()
                .map(DocumentSnapshot::getData)
                .collect(Collectors.toList());
            tasks.sort(Comparator.comparingInt(this::parseTaskId));
            normalizeTaskDependenciesInPlace(tasks);
            return tasks;
        } catch (Exception e) {
            System.err.println("❌ getTasks error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> regenerateTasks(String assignmentId) {
        try {
            Firestore db = getDb();
            DocumentSnapshot doc = db.collection("groups")
                .document(assignmentId).get().get();
            String brief = (String) doc.get("brief");
            List<Map<String, Object>> members = getMembers(db, assignmentId);

            deleteSubcollection(db, "groupTasks", assignmentId, "tasks");
            List<Map<String, Object>> newDistribution = aiService.generateFullPlan(brief, members);
            if (newDistribution.isEmpty()) {
                throw new RuntimeException("AI did not generate tasks/distribution during regenerate.");
            }

            List<Map<String, Object>> newTasks = flattenTasksFromDistribution(newDistribution);
            normalizeDependenciesWithTaskIds(newTasks, newDistribution);
            for (Map<String, Object> task : newTasks) {
                db.collection("groupTasks").document(assignmentId)
                    .collection("tasks").add(task).get();
            }

            saveDistribution(db, assignmentId, newDistribution);
            return getTasks(assignmentId);
        } catch (Exception e) {
            System.err.println("❌ regenerateTasks error: " + e.getMessage());
            throw new RuntimeException("Regenerate failed (AI-only mode): " + e.getMessage(), e);
        }
    }

    public List<Map<String, Object>> getDistribution(String assignmentId) {
        try {
            Firestore db = getDb();
            QuerySnapshot snapshot = db.collection("groupDistributions")
                .document(assignmentId)
                .collection("assignments")
                .get().get();
            List<Map<String, Object>> distribution = snapshot.getDocuments().stream()
                .map(DocumentSnapshot::getData)
                .collect(Collectors.toList());
            List<Map<String, Object>> tasks = getTasks(assignmentId);
            normalizeDistributionDependenciesInPlace(distribution, tasks);
            return distribution;
        } catch (Exception e) {
            System.err.println("❌ getDistribution error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> regenerateDistribution(String assignmentId) {
        try {
            Firestore db = getDb();
            List<Map<String, Object>> tasks = getTasks(assignmentId);
            List<Map<String, Object>> members = getMembers(db, assignmentId);
            List<Map<String, Object>> distribution =
                aiService.distributeTasks(tasks, members);
            normalizeDistributionDependenciesInPlace(distribution, tasks);
            saveDistribution(db, assignmentId, distribution);
            return distribution;
        } catch (Exception e) {
            System.err.println("❌ regenerateDistribution error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public Map<String, Object> getSetup(String assignmentId) {
        try {
            Firestore db = getDb();
            DocumentSnapshot doc = db.collection("groups")
                .document(assignmentId).get().get();
            Map<String, Object> data = new HashMap<>(doc.getData());
            data.put("members", getMembers(db, assignmentId));
            return data;
        } catch (Exception e) {
            System.err.println("❌ getSetup error: " + e.getMessage());
            return Collections.emptyMap();
        }
    }

    public String updateGroupAssignment(String assignmentId, Map<String, Object> body) {
        try {
            Firestore db = getDb();
            List<Map<String, Object>> members =
                (List<Map<String, Object>>) body.get("members");

            List<String> memberInitials = members.stream()
                .map(m -> {
                    String name = (String) m.get("name");
                    return (name != null && !name.isEmpty())
                        ? String.valueOf(name.charAt(0)).toUpperCase() : "?";
                })
                .collect(Collectors.toList());

            Map<String, Object> groupData = new HashMap<>(body);
            groupData.put("memberInitials", memberInitials);
            db.collection("groups").document(assignmentId).set(groupData).get();
            System.out.println("✅ Updated group data for assignment: " + assignmentId);

            String brief = (String) body.get("brief");
            System.out.println("🤖 Generating tasks + distribution with mega-prompt...");
            List<Map<String, Object>> distribution = aiService.generateFullPlan(brief, members);
            if (distribution == null || distribution.isEmpty()) {
                System.err.println("❌ AI service returned empty distribution");
                throw new RuntimeException("AI generation failed - no distribution generated");
            }

            List<Map<String, Object>> tasks = flattenTasksFromDistribution(distribution);
            normalizeDependenciesWithTaskIds(tasks, distribution);

            if (tasks.size() < 4) {
                System.out.println("⚠️ updateGroupAssignment generated only " + tasks.size() + " unique tasks. Retrying with extract+distribute fallback...");

                List<Map<String, Object>> recoveredTasks = aiService.extractTasksAiOnly(brief, members);
                List<Map<String, Object>> recoveredDistribution = aiService.distributeTasks(recoveredTasks, members);
                List<Map<String, Object>> recoveredFlatTasks = flattenTasksFromDistribution(recoveredDistribution);
                normalizeDependenciesWithTaskIds(recoveredFlatTasks, recoveredDistribution);

                if (recoveredFlatTasks.size() > tasks.size()) {
                    System.out.println("✅ Recovery produced " + recoveredFlatTasks.size() + " tasks. Using recovered result.");
                    tasks = recoveredFlatTasks;
                    distribution = recoveredDistribution;
                } else {
                    System.out.println("⚠️ Recovery did not improve task count. Keeping original result.");
                }
            }

            if (tasks.isEmpty()) {
                System.err.println("❌ AI service returned distribution but no tasks");
                throw new RuntimeException("AI generation failed - no tasks generated");
            }

            System.out.println("✅ AI generation returned " + tasks.size() + " tasks and " + distribution.size() + " members");
            deleteSubcollection(db, "groupTasks", assignmentId, "tasks");
            for (int i = 0; i < tasks.size(); i++) {
                db.collection("groupTasks").document(assignmentId)
                  .collection("tasks").add(tasks.get(i)).get();
            }
            System.out.println("✅ Tasks saved to Firestore");

            saveDistribution(db, assignmentId, distribution);
            System.out.println("✅ updateGroupAssignment completed successfully");
            return assignmentId;
        } catch (Exception e) {
            System.err.println("❌ updateGroupAssignment error: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to update group assignment: " + e.getMessage(), e);
        }
    }

    public void confirmAndSync(String assignmentId, String userId) {
        try {
            Firestore db = getDb();
            System.out.println("🔄 confirmAndSync called for assignment: " + assignmentId);
            
            // Check if document exists, create empty one first if needed
            boolean updated = false;
            try {
                System.out.println("  Attempting to update existing document...");
                db.collection("groupDistributions").document(assignmentId).update("confirmed", true).get();
                System.out.println("✅ Distribution confirmed (updated existing)");
                updated = true;
            } catch (Exception updateEx) {
                System.out.println("⚠️ Update failed: " + updateEx.getMessage());
                System.out.println("  Creating new document instead...");
                
                // If update fails (document doesn't exist), create it
                Map<String, Object> data = new HashMap<>();
                data.put("confirmed", true);
                data.put("confirmedAt", System.currentTimeMillis());
                data.put("assignmentId", assignmentId);
                
                try {
                    db.collection("groupDistributions").document(assignmentId).set(data).get();
                    System.out.println("✅ Distribution confirmed (created new)");
                    updated = true;
                } catch (Exception setEx) {
                    System.out.println("❌ Set operation also failed: " + setEx.getMessage());
                    throw setEx;
                }
            }
            
            if (!updated) {
                throw new RuntimeException("Failed to confirm distribution - neither update nor set succeeded");
            }
        } catch (Exception e) {
            System.err.println("❌ confirmAndSync error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Distribution confirmation failed: " + e.getMessage(), e);
        }
    }

    public void deleteGroupAssignment(String assignmentId) {
        try {
            Firestore db = getDb();

            deleteSubcollection(db, "groups", assignmentId, "members");
            deleteSubcollection(db, "groupTasks", assignmentId, "tasks");
            deleteSubcollection(db, "groupDistributions", assignmentId, "assignments");

            db.collection("groups").document(assignmentId).delete().get();
            db.collection("groupTasks").document(assignmentId).delete().get();
            db.collection("groupDistributions").document(assignmentId).delete().get();

            System.out.println("✅ Group assignment deleted (planner tasks not affected)");
        } catch (Exception e) {
            System.err.println("❌ deleteGroupAssignment error: " + e.getMessage());
            throw new RuntimeException("Failed to delete group assignment", e);
        }
    }

    // ── private helpers (all take db as param to reuse the same instance) ──

    private List<Map<String, Object>> getMembers(Firestore db, String assignmentId) throws Exception {
        QuerySnapshot snapshot = db.collection("groups")
            .document(assignmentId)
            .collection("members")
            .get().get();
        return snapshot.getDocuments().stream()
            .map(DocumentSnapshot::getData)
            .collect(Collectors.toList());
    }

    private void deleteSubcollection(Firestore db, String collection, String docId,
                                      String subcollection) throws Exception {
        QuerySnapshot snapshot = db.collection(collection)
            .document(docId)
            .collection(subcollection)
            .get().get();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            doc.getReference().delete().get();
        }
    }

    private void saveDistribution(Firestore db, String assignmentId,
                                   List<Map<String, Object>> distribution) throws Exception {
        deleteSubcollection(db, "groupDistributions", assignmentId, "assignments");
        for (Map<String, Object> member : distribution) {
            db.collection("groupDistributions").document(assignmentId)
              .collection("assignments").add(member).get();
        }
    }

    private List<Map<String, Object>> flattenTasksFromDistribution(List<Map<String, Object>> distribution) {
        List<Map<String, Object>> flat = new ArrayList<>();
        Set<String> seen = new HashSet<>();

        for (Map<String, Object> member : distribution) {
            Object tasksRaw = member.get("tasks");
            if (!(tasksRaw instanceof List<?> taskItems)) continue;

            for (Object item : taskItems) {
                if (!(item instanceof Map<?, ?> taskMap)) continue;

                Object rawTitle = taskMap.containsKey("title") ? taskMap.get("title") : "Task";
                Object rawDescription = taskMap.containsKey("description") ? taskMap.get("description") : "";
                String title = String.valueOf(rawTitle);
                String description = String.valueOf(rawDescription);
                String signature = (title + "||" + description).toLowerCase(Locale.ROOT);
                if (!seen.add(signature)) continue;

                Map<String, Object> task = new LinkedHashMap<>();
                task.put("title", title);
                task.put("description", description);
                Object rawEffort = taskMap.containsKey("effort") ? taskMap.get("effort") : "Medium";
                task.put("effort", String.valueOf(rawEffort));
                task.put("dependencies", taskMap.get("dependencies"));
                flat.add(task);
            }
        }

        for (int i = 0; i < flat.size(); i++) {
            flat.get(i).put("id", i + 1);
        }

        return flat;
    }

    private int parseTaskId(Map<String, Object> task) {
        Object rawId = task.get("id");
        if (rawId instanceof Integer i) return i;
        if (rawId instanceof Number n) return n.intValue();
        if (rawId instanceof String s) {
            try {
                return Integer.parseInt(s);
            } catch (NumberFormatException ignored) {
                return Integer.MAX_VALUE;
            }
        }
        return Integer.MAX_VALUE;
    }

    private void normalizeDependenciesWithTaskIds(List<Map<String, Object>> tasks,
                                                  List<Map<String, Object>> distribution) {
        normalizeTaskDependenciesInPlace(tasks);
        normalizeDistributionDependenciesInPlace(distribution, tasks);
    }

    private void normalizeTaskDependenciesInPlace(List<Map<String, Object>> tasks) {
        if (tasks == null || tasks.isEmpty()) return;
        Map<String, Integer> titleToId = buildTaskTitleToIdMap(tasks);
        Set<Integer> validIds = new HashSet<>(titleToId.values());

        for (Map<String, Object> task : tasks) {
            Integer currentTaskId = safeTaskId(task);
            Object normalized = normalizeDependenciesValue(task.get("dependencies"), titleToId, validIds, currentTaskId);
            task.put("dependencies", normalized);
        }
    }

    private void normalizeDistributionDependenciesInPlace(List<Map<String, Object>> distribution,
                                                          List<Map<String, Object>> tasks) {
        if (distribution == null || distribution.isEmpty()) return;
        Map<String, Integer> titleToId = buildTaskTitleToIdMap(tasks);
        Set<Integer> validIds = new HashSet<>(titleToId.values());

        for (Map<String, Object> member : distribution) {
            Object tasksRaw = member.get("tasks");
            if (!(tasksRaw instanceof List<?> memberTasks)) continue;

            for (Object item : memberTasks) {
                if (!(item instanceof Map<?, ?> map)) continue;
                @SuppressWarnings("unchecked")
                Map<String, Object> memberTask = (Map<String, Object>) map;
                Integer currentTaskId = safeTaskId(memberTask);
                if (currentTaskId == null) {
                    Object titleRaw = memberTask.get("title");
                    String title = titleRaw == null ? "" : String.valueOf(titleRaw).trim().toLowerCase(Locale.ROOT);
                    currentTaskId = titleToId.get(title);
                    if (currentTaskId == null && !title.isEmpty()) {
                        currentTaskId = titleToId.get(normalizeKey(title));
                    }
                }

                Object normalized = normalizeDependenciesValue(
                    memberTask.get("dependencies"),
                    titleToId,
                    validIds,
                    currentTaskId
                );
                memberTask.put("dependencies", normalized);
            }
        }
    }

    private Map<String, Integer> buildTaskTitleToIdMap(List<Map<String, Object>> tasks) {
        Map<String, Integer> titleToId = new HashMap<>();
        if (tasks == null) return titleToId;

        for (Map<String, Object> task : tasks) {
            int id = parseTaskId(task);
            if (id == Integer.MAX_VALUE) continue;
            String title = task.get("title") == null ? "" : String.valueOf(task.get("title")).trim().toLowerCase(Locale.ROOT);
            if (!title.isEmpty()) {
                titleToId.put(title, id);
                String normalizedTitle = normalizeKey(title);
                if (!normalizedTitle.isEmpty()) {
                    titleToId.put(normalizedTitle, id);
                }
            }
        }
        return titleToId;
    }

    private Object normalizeDependenciesValue(Object rawDependencies,
                                              Map<String, Integer> titleToId,
                                              Set<Integer> validIds,
                                              Integer currentTaskId) {
        if (rawDependencies == null) return null;

        String raw = String.valueOf(rawDependencies).trim();
        if (raw.isEmpty() || raw.equalsIgnoreCase("null") || raw.equalsIgnoreCase("none")) {
            return null;
        }

        List<String> normalizedTokens = new ArrayList<>();
        for (String token : raw.split(",")) {
            String normalized = normalizeDependencyToken(token, titleToId, validIds, currentTaskId);
            if (normalized != null && !normalized.isBlank()) {
                normalizedTokens.add(normalized);
            }
        }

        if (normalizedTokens.isEmpty()) return null;
        return String.join(",", normalizedTokens);
    }

    private String normalizeDependencyToken(String token,
                                            Map<String, Integer> titleToId,
                                            Set<Integer> validIds,
                                            Integer currentTaskId) {
        String trimmed = token == null ? "" : token.trim();
        if (trimmed.isEmpty()) return null;

        Integer parsed = parseInteger(trimmed);
        if (parsed == null && trimmed.toLowerCase(Locale.ROOT).startsWith("task ")) {
            parsed = parseInteger(trimmed.substring(5).trim());
        }
        if (parsed == null) {
            parsed = extractFirstPositiveInteger(trimmed);
        }

        if (parsed != null) {
            if (parsed <= 0) return null;
            if (validIds != null && !validIds.isEmpty() && !validIds.contains(parsed)) return null;
            if (currentTaskId != null && currentTaskId.equals(parsed)) return null;
            return String.valueOf(parsed);
        }

        Integer mapped = titleToId.get(trimmed.toLowerCase(Locale.ROOT));
        if (mapped != null && mapped > 0) {
            return String.valueOf(mapped);
        }

        String normalizedToken = normalizeKey(trimmed);
        if (!normalizedToken.isEmpty()) {
            Integer normalizedMapped = titleToId.get(normalizedToken);
            if (normalizedMapped != null && normalizedMapped > 0) {
                return String.valueOf(normalizedMapped);
            }

            for (Map.Entry<String, Integer> entry : titleToId.entrySet()) {
                String key = entry.getKey();
                if (key.isEmpty()) continue;
                if (normalizedToken.contains(key) || key.contains(normalizedToken)) {
                    Integer candidate = entry.getValue();
                    if (candidate != null && candidate > 0) {
                        if (validIds == null || validIds.isEmpty() || validIds.contains(candidate)) {
                            return String.valueOf(candidate);
                        }
                    }
                }
            }
        }

        return null;
    }

    private Integer safeTaskId(Map<String, Object> task) {
        int id = parseTaskId(task);
        return id == Integer.MAX_VALUE ? null : id;
    }

    private String normalizeKey(String text) {
        if (text == null) return "";
        return text.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "");
    }

    private Integer extractFirstPositiveInteger(String text) {
        if (text == null) return null;
        Matcher matcher = Pattern.compile("(\\d+)").matcher(text);
        if (!matcher.find()) return null;
        return parseInteger(matcher.group(1));
    }

    private Integer parseInteger(String value) {
        try {
            return Integer.parseInt(value);
        } catch (Exception ignored) {
            return null;
        }
    }
}