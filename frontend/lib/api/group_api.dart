import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL — same as PlannerApi
const String _baseUrl = 'http://localhost:9091';

/// ── Data Models ──────────────────────────────────────────────────────────────

class GroupAssignment {
  final String id;
  final String courseCode;
  final String groupName;
  final String assignmentTitle;
  final String deadline; // ISO string, e.g. "2023-11-15T23:59"
  final String status; // "On track" | "At risk"
  final List<String> memberInitials;

  GroupAssignment({
    required this.id,
    required this.courseCode,
    required this.groupName,
    required this.assignmentTitle,
    required this.deadline,
    required this.status,
    required this.memberInitials,
  });

  factory GroupAssignment.fromJson(Map<String, dynamic> j) => GroupAssignment(
    id: j['id'] as String? ?? '',
    courseCode: j['courseCode'] as String? ?? '',
    groupName: j['groupName'] as String? ?? '',
    assignmentTitle: j['assignmentTitle'] as String? ?? '',
    deadline: j['deadline'] as String? ?? '',
    status: j['status'] as String? ?? 'On track',
    memberInitials:
        (j['memberInitials'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

class GroupMember {
  final String name;
  final List<String> strengths;

  GroupMember({required this.name, required this.strengths});

  Map<String, dynamic> toJson() => {'name': name, 'strengths': strengths};
}

class GroupTask {
  final int id;
  final String title;
  final String description;
  final String effort; // "Low" | "Medium" | "High"
  final String? dependencies; // task id as string, or null

  GroupTask({
    required this.id,
    required this.title,
    required this.description,
    required this.effort,
    this.dependencies,
  });

  factory GroupTask.fromJson(Map<String, dynamic> j) => GroupTask(
    id: j['id'] as int? ?? 0,
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    effort: j['effort'] as String? ?? 'Medium',
    dependencies: j['dependencies'] as String?,
  );
}

class MemberDistribution {
  final String name;
  final String initial;
  final String strengths; // comma-separated display string
  final int taskCount;
  final List<MemberTask> tasks;

  MemberDistribution({
    required this.name,
    required this.initial,
    required this.strengths,
    required this.taskCount,
    required this.tasks,
  });

  factory MemberDistribution.fromJson(Map<String, dynamic> j) =>
      MemberDistribution(
        name: j['name'] as String? ?? '',
        initial: j['initial'] as String? ?? '',
        strengths: j['strengths'] as String? ?? '',
        taskCount: j['taskCount'] as int? ?? 0,
        tasks:
            (j['tasks'] as List<dynamic>?)
                ?.map((e) => MemberTask.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class MemberTask {
  final String title;
  final String description;
  final String effort;
  final String reason;
  final String? dependencies;

  MemberTask({
    required this.title,
    required this.description,
    required this.effort,
    required this.reason,
    this.dependencies,
  });

  factory MemberTask.fromJson(Map<String, dynamic> j) => MemberTask(
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    effort: j['effort'] as String? ?? 'Medium',
    reason: j['reason'] as String? ?? '',
    dependencies: j['dependencies'] as String?,
  );
}

/// ── API Client ───────────────────────────────────────────────────────────────

class GroupApi {
  static String _userId = 'default-user';

  static void setUserId(String userId) => _userId = userId;

  // ── 6.1 Group Overview ──────────────────────────────────────────────────────

  /// Fetch all group assignments for the current user.
  static Future<List<GroupAssignment>> getGroupAssignments() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/groups?userId=$_userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => GroupAssignment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── 6.2 Create Group Assignment (Generate Tasks) ────────────────────────────

  /// Submit setup form → backend calls AI to extract tasks → returns assignment id.
  /// Frontend then navigates to Task Breakdown with the returned id.
  static Future<String?> createGroupAssignment({
    required String groupName,
    required String courseName,
    required String assignmentTitle,
    required DateTime deadline,
    required List<GroupMember> members,
    required String brief,
  }) async {
    try {
      final body = jsonEncode({
        'userId': _userId,
        'groupName': groupName,
        'courseName': courseName,
        'assignmentTitle': assignmentTitle,
        'deadline': deadline.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        'brief': brief,
      });
      final res = await http.post(
        Uri.parse('$_baseUrl/api/groups/create'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (res.statusCode != 200 && res.statusCode != 201) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['assignmentId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── 6.3 Task Breakdown ──────────────────────────────────────────────────────

  /// Fetch AI-generated tasks for a given assignment.
  static Future<List<GroupTask>> getTaskBreakdown(String assignmentId) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/groups/$assignmentId/tasks'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => GroupTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Regenerate tasks from the same brief (AI re-runs extraction).
  static Future<List<GroupTask>> regenerateTasks(String assignmentId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/groups/$assignmentId/tasks/regenerate'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => GroupTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── 6.4 Task Distribution ───────────────────────────────────────────────────

  /// Fetch AI distribution (which task goes to which member).
  static Future<List<MemberDistribution>> getTaskDistribution(
    String assignmentId,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/groups/$assignmentId/distribution'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => MemberDistribution.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Regenerate task distribution (AI re-assigns tasks to members).
  static Future<List<MemberDistribution>> regenerateDistribution(
    String assignmentId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/groups/$assignmentId/distribution/regenerate'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => MemberDistribution.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Confirm and save the current distribution (sync to planner).
  static Future<bool> confirmDistribution(String assignmentId) async {
    try {
      final res = await http.post(
        Uri.parse(
          '$_baseUrl/api/groups/$assignmentId/distribution/confirm?userId=$_userId',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── 6.5 Edit Setup ──────────────────────────────────────────────────────────

  /// Fetch existing assignment data for pre-filling edit form.
  static Future<Map<String, dynamic>?> getAssignmentSetup(
    String assignmentId,
  ) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/groups/$assignmentId/setup'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Update assignment setup and re-run AI distribution.
  static Future<String?> updateGroupAssignment({
    required String assignmentId,
    required String groupName,
    required String courseName,
    required String assignmentTitle,
    required DateTime deadline,
    required List<GroupMember> members,
    required String brief,
  }) async {
    try {
      final body = jsonEncode({
        'userId': _userId,
        'groupName': groupName,
        'courseName': courseName,
        'assignmentTitle': assignmentTitle,
        'deadline': deadline.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        'brief': brief,
      });
      final res = await http.put(
        Uri.parse('$_baseUrl/api/groups/$assignmentId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['assignmentId'] as String?;
    } catch (_) {
      return null;
    }
  }
}
