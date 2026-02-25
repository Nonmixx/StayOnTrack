import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stayontrack/user_session.dart';
/// Base URL — same as PlannerApi
import 'planner_api.dart' show baseUrl;

String get _baseUrl => baseUrl;
String? _lastRegenerateTasksError;
String? _lastRegenerateDistributionError;
String? _lastUpdateGroupError;

String? get lastRegenerateTasksError => _lastRegenerateTasksError;
String? get lastRegenerateDistributionError => _lastRegenerateDistributionError;
String? get lastUpdateGroupError => _lastUpdateGroupError;

/// ── Data Models ──────────────────────────────────────────────────────────────

class GroupAssignment {
  final String id;
  final String courseCode;
  final String groupName;
  final String assignmentTitle;
  final String deadline; // ISO string, e.g. "2023-11-15T23:59"
  final List<String> memberInitials;

  GroupAssignment({
    required this.id,
    required this.courseCode,
    required this.groupName,
    required this.assignmentTitle,
    required this.deadline,
    required this.memberInitials,
  });

  factory GroupAssignment.fromJson(Map<String, dynamic> j) => GroupAssignment(
    id: j['id'] as String? ?? '',
    courseCode: (j['courseCode'] ?? j['courseName']) as String? ?? '',
    groupName: j['groupName'] as String? ?? '',
    assignmentTitle: j['assignmentTitle'] as String? ?? '',
    deadline: j['deadline'] as String? ?? '',
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

  static int _parseId(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    if (rawId is String) return int.tryParse(rawId) ?? 0;
    return 0;
  }

  factory GroupTask.fromJson(Map<String, dynamic> j) => GroupTask(
    id: _parseId(j['id']),
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
  static String get _userId => UserSession.uid ?? 'default-user';

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
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/groups/create'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode != 200 && res.statusCode != 201) {
        print('❌ createGroupAssignment HTTP ${res.statusCode}: ${res.body}');
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['assignmentId'] as String?;
    } catch (e, stack) {
      print('❌ createGroupAssignment error: $e');
      print('❌ Stack: $stack');
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
      _lastRegenerateTasksError = null;
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/groups/$assignmentId/tasks/regenerate'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) {
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final backendMsg = (body['error'] as String?) ?? '';
          if (backendMsg.toLowerCase().contains('quota') ||
              backendMsg.toLowerCase().contains('429')) {
            _lastRegenerateTasksError =
                'AI quota exceeded. Please try again later or switch API key.';
          } else if (backendMsg.toLowerCase().contains('api key') ||
              backendMsg.toLowerCase().contains('unauthorized') ||
              backendMsg.toLowerCase().contains('forbidden')) {
            _lastRegenerateTasksError =
                'AI API key/config invalid. Please check backend configuration.';
          } else {
            _lastRegenerateTasksError =
                'AI task extraction unavailable. Please try again later.';
          }
        } catch (_) {
          _lastRegenerateTasksError =
              'Regenerate failed (HTTP ${res.statusCode})';
        }
        return [];
      }
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => GroupTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('TimeoutException')) {
        _lastRegenerateTasksError =
            'Regenerate timed out. Please check backend/AI service and try again.';
      } else {
        _lastRegenerateTasksError = 'Regenerate failed. Please try again.';
      }
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
      _lastRegenerateDistributionError = null;
      final res = await http
          .post(
            Uri.parse(
              '$_baseUrl/api/groups/$assignmentId/distribution/regenerate',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) {
        _lastRegenerateDistributionError =
            'Regenerate distribution failed (HTTP ${res.statusCode})';
        return [];
      }
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => MemberDistribution.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _lastRegenerateDistributionError = e.toString();
      return [];
    }
  }

  /// Confirm and save the current distribution (sync to planner).
  static Future<bool> confirmDistribution(String assignmentId) async {
    try {
      print(
        '📤 confirmDistribution: sending to $_baseUrl/api/groups/$assignmentId/distribution/confirm',
      );
      final res = await http
          .post(
            Uri.parse(
              '$_baseUrl/api/groups/$assignmentId/distribution/confirm?userId=$_userId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      print('📥 confirmDistribution HTTP ${res.statusCode}');
      print('📥 Response body: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final success = data['success'] as bool? ?? true;
          print('📊 confirmDistribution success: $success');
          return success;
        } catch (parseError) {
          print(
            '⚠️ Failed to parse response: $parseError. Treating as success.',
          );
          return true;
        }
      } else {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          print('❌ confirmDistribution error: ${data['error']}');
        } catch (_) {
          print('❌ confirmDistribution HTTP ${res.statusCode}: ${res.body}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ confirmDistribution exception: $e');
      print('❌ Stack: $stackTrace');
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
      _lastUpdateGroupError = null;
      final body = jsonEncode({
        'userId': _userId,
        'groupName': groupName,
        'courseName': courseName,
        'assignmentTitle': assignmentTitle,
        'deadline': deadline.toIso8601String(),
        'members': members.map((m) => m.toJson()).toList(),
        'brief': brief,
      });
      print(
        '📤 updateGroupAssignment: Sending to $_baseUrl/api/groups/$assignmentId',
      );
      print('📋 Members count: ${members.length}');
      print(
        '📝 Brief: ${brief.length > 100 ? brief.substring(0, 100) : brief}...',
      );

      final res = await http
          .put(
            Uri.parse('$_baseUrl/api/groups/$assignmentId'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 90));

      print('📥 updateGroupAssignment HTTP ${res.statusCode}');
      print('📥 Response: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final success = data['success'] as bool? ?? true;
          if (!success) {
            print('❌ API returned error: ${data['error']}');
            _lastUpdateGroupError =
                (data['error'] as String?) ??
                'Update failed while regenerating tasks.';
            return null;
          }
          return data['assignmentId'] as String?;
        } catch (parseError) {
          print('❌ Failed to parse response: $parseError');
          _lastUpdateGroupError = 'Update response parse error: $parseError';
          return null;
        }
      } else {
        print('❌ updateGroupAssignment failed with status ${res.statusCode}');
        try {
          final errorData = jsonDecode(res.body) as Map<String, dynamic>;
          print('❌ Error details: ${errorData['error']}');
          _lastUpdateGroupError =
              (errorData['error'] as String?) ??
              'Update failed (HTTP ${res.statusCode}).';
        } catch (_) {
          print('❌ Response body: ${res.body}');
          _lastUpdateGroupError = 'Update failed (HTTP ${res.statusCode}).';
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ updateGroupAssignment exception: $e');
      print('❌ Stack: $stackTrace');
      _lastUpdateGroupError = e.toString().contains('TimeoutException')
          ? 'Update timed out. Backend/AI may still finish in background; please refresh Task Breakdown/Distribution.'
          : 'Update request failed: $e';
      return null;
    }
  }

  /// Delete a group assignment and all related backend data.
  static Future<bool> deleteGroupAssignment(String assignmentId) async {
    try {
      final res = await http
          .delete(Uri.parse('$_baseUrl/api/groups/$assignmentId'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
