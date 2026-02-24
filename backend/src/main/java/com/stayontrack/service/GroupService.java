package com.stayontrack.service;

import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class GroupService {

    @Autowired
    private AIService aiService;

    private final Firestore db = FirestoreClient.getFirestore();

    public String createGroupAssignment(Map<String, Object> body) {
        System.out.println("✅ createGroupAssignment called");
        System.out.println("📦 Body keys: " + body.keySet());

        try {
            DocumentReference docRef = db.collection("groups").document();
            String assignmentId = docRef.getId();
            System.out.println("📝 assignmentId: " + assignmentId);

            List<Map<String, Object>> members =
                (List<Map<String, Object>>) body.get("members");

            // ── FIX: compute memberInitials and save into group document
            //    so GroupPage can show avatars without extra queries ──
            List<String> memberInitials = members.stream()
                .map(m -> {
                    String name = (String) m.get("name");
                    return (name != null && !name.isEmpty())
                        ? String.valueOf(name.charAt(0)).toUpperCase() : "?";
                })
                .collect(Collectors.toList());

            Map<String, Object> groupData = new HashMap<>(body);
            groupData.put("createdAt", FieldValue.serverTimestamp());
            groupData.put("status", "On track");
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
            List<Map<String, Object>> tasks = aiService.extractTasks(brief, members);
            System.out.println("✅ AI returned " + tasks.size() + " tasks");

            if (tasks.isEmpty()) {
                System.err.println("⚠️ AI returned 0 tasks — check AIService logs above");
            }

            for (int i = 0; i < tasks.size(); i++) {
                tasks.get(i).put("id", i + 1);
                db.collection("groupTasks").document(assignmentId)
                  .collection("tasks").add(tasks.get(i)).get();
            }
            System.out.println("✅ Tasks saved to Firestore");

            List<Map<String, Object>> distribution =
                aiService.distributeTasks(tasks, members);
            System.out.println("✅ AI distribution for " + distribution.size() + " members");
            saveDistribution(assignmentId, distribution);
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
            QuerySnapshot snapshot = db.collection("groupTasks")
                .document(assignmentId)
                .collection("tasks")
                .get().get();
            return snapshot.getDocuments().stream()
                .map(DocumentSnapshot::getData)
                .collect(Collectors.toList());
        } catch (Exception e) {
            System.err.println("❌ getTasks error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> regenerateTasks(String assignmentId) {
        try {
            DocumentSnapshot doc = db.collection("groups")
                .document(assignmentId).get().get();
            String brief = (String) doc.get("brief");
            List<Map<String, Object>> members = getMembers(assignmentId);
            deleteSubcollection("groupTasks", assignmentId, "tasks");
            List<Map<String, Object>> newTasks = aiService.extractTasks(brief, members);
            for (int i = 0; i < newTasks.size(); i++) {
                newTasks.get(i).put("id", i + 1);
                db.collection("groupTasks").document(assignmentId)
                  .collection("tasks").add(newTasks.get(i)).get();
            }
            return newTasks;
        } catch (Exception e) {
            System.err.println("❌ regenerateTasks error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> getDistribution(String assignmentId) {
        try {
            QuerySnapshot snapshot = db.collection("groupDistributions")
                .document(assignmentId)
                .collection("assignments")
                .get().get();
            return snapshot.getDocuments().stream()
                .map(DocumentSnapshot::getData)
                .collect(Collectors.toList());
        } catch (Exception e) {
            System.err.println("❌ getDistribution error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> regenerateDistribution(String assignmentId) {
        try {
            List<Map<String, Object>> tasks = getTasks(assignmentId);
            List<Map<String, Object>> members = getMembers(assignmentId);
            List<Map<String, Object>> distribution =
                aiService.distributeTasks(tasks, members);
            saveDistribution(assignmentId, distribution);
            return distribution;
        } catch (Exception e) {
            System.err.println("❌ regenerateDistribution error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public Map<String, Object> getSetup(String assignmentId) {
        try {
            DocumentSnapshot doc = db.collection("groups")
                .document(assignmentId).get().get();
            Map<String, Object> data = new HashMap<>(doc.getData());
            data.put("members", getMembers(assignmentId));
            return data;
        } catch (Exception e) {
            System.err.println("❌ getSetup error: " + e.getMessage());
            return Collections.emptyMap();
        }
    }

    public String updateGroupAssignment(String assignmentId, Map<String, Object> body) {
        try {
            List<Map<String, Object>> members =
                (List<Map<String, Object>>) body.get("members");

            // ── FIX: recompute memberInitials on update ──
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

            String brief = (String) body.get("brief");
            List<Map<String, Object>> tasks = aiService.extractTasks(brief, members);
            deleteSubcollection("groupTasks", assignmentId, "tasks");
            for (int i = 0; i < tasks.size(); i++) {
                tasks.get(i).put("id", i + 1);
                db.collection("groupTasks").document(assignmentId)
                  .collection("tasks").add(tasks.get(i)).get();
            }
            List<Map<String, Object>> distribution =
                aiService.distributeTasks(tasks, members);
            saveDistribution(assignmentId, distribution);
            return assignmentId;
        } catch (Exception e) {
            System.err.println("❌ updateGroupAssignment error: " + e.getMessage());
            throw new RuntimeException("Failed to update group assignment", e);
        }
    }

    public void confirmAndSync(String assignmentId, String userId) {
        try {
            List<Map<String, Object>> distribution = getDistribution(assignmentId);
            for (Map<String, Object> member : distribution) {
                List<Map<String, Object>> tasks =
                    (List<Map<String, Object>>) member.get("tasks");
                for (Map<String, Object> task : tasks) {
                    Map<String, Object> plannerTask = new HashMap<>();
                    plannerTask.put("userId", userId);
                    plannerTask.put("title", task.get("title"));
                    plannerTask.put("assignmentId", assignmentId);
                    plannerTask.put("assignedTo", member.get("name"));
                    plannerTask.put("synced", true);
                    db.collection("plannerTasks").add(plannerTask).get();
                }
            }
        } catch (Exception e) {
            System.err.println("❌ confirmAndSync error: " + e.getMessage());
            throw new RuntimeException("Planner sync failed", e);
        }
    }

    private List<Map<String, Object>> getMembers(String assignmentId) throws Exception {
        QuerySnapshot snapshot = db.collection("groups")
            .document(assignmentId)
            .collection("members")
            .get().get();
        return snapshot.getDocuments().stream()
            .map(DocumentSnapshot::getData)
            .collect(Collectors.toList());
    }

    private void deleteSubcollection(String collection, String docId,
                                      String subcollection) throws Exception {
        QuerySnapshot snapshot = db.collection(collection)
            .document(docId)
            .collection(subcollection)
            .get().get();
        for (DocumentSnapshot doc : snapshot.getDocuments()) {
            doc.getReference().delete().get();
        }
    }

    private void saveDistribution(String assignmentId,
                                   List<Map<String, Object>> distribution) throws Exception {
        deleteSubcollection("groupDistributions", assignmentId, "assignments");
        for (Map<String, Object> member : distribution) {
            db.collection("groupDistributions").document(assignmentId)
              .collection("assignments").add(member).get();
        }
    }
}