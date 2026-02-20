import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL for the StayOnTrack backend.
/// - Chrome/Windows: localhost works
/// - Android emulator: use http://10.0.2.2:9091
/// - Physical device: use your PC's IP (e.g. http://192.168.1.x:9091)
const String baseUrl = 'http://localhost:9091';

///Planner Engine API client.
class PlannerApi {
  static String _userId = 'default-user';

  static void setUserId(String userId) => _userId = userId;

  /// Get today's tasks for Home page.
  static Future<List<PlannerTask>> getTodaysTasks() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/planner/today?userId=$_userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => PlannerTask.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get weekly summary (tasks completed, overdue, completion rate).
  static Future<WeeklySummary?> getWeeklySummary() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/planner/weekly-summary?userId=$_userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      return WeeklySummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Toggle task completion.
  static Future<bool> toggleTaskCompletion(String taskId, bool completed) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/planner/tasks/$taskId/complete?completed=$completed'),
    );
    return res.statusCode == 200;
  }

  /// Regenerate next week plan (from Weekly Check-In).
  static Future<PlannerWeek?> regenerateNextWeek({
    String? feedback,
    int availableStudyHoursNextWeek = 20,
  }) async {
    final body = jsonEncode({
      'feedback': feedback ?? '',
      'availableStudyHoursNextWeek': availableStudyHoursNextWeek,
    });
    final res = await http.post(
      Uri.parse('$baseUrl/api/planner/regenerate?userId=$_userId'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode != 200) return null;
    return PlannerWeek.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Get tasks for a specific week.
  static Future<List<PlannerTask>> getWeekTasks(String weekStartDate) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/planner/week?userId=$_userId&weekStartDate=$weekStartDate'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => PlannerTask.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate initial plan (after setup).
  static Future<PlannerWeek?> generatePlan({int availableHours = 20}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/planner/generate?userId=$_userId&availableHours=$availableHours'),
    );
    if (res.statusCode != 200) return null;
    return PlannerWeek.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Get deadlines (for planner month view, nearest deadline for alert).
  static Future<List<Deadline>> getDeadlines() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/deadlines?userId=$_userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Deadline.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

class Deadline {
  final String id;
  final String title;
  final String course;
  final String? dueDate;
  final String? type;

  Deadline({required this.id, required this.title, required this.course, this.dueDate, this.type});

  factory Deadline.fromJson(Map<String, dynamic> json) {
    String? dueDateStr;
    final d = json['dueDate'];
    if (d is String) dueDateStr = d;
    else if (d is List && d.length >= 3) dueDateStr = '${d[0]}-${d[1].toString().padLeft(2, '0')}-${d[2].toString().padLeft(2, '0')}';
    return Deadline(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      course: json['course'] as String? ?? '',
      dueDate: dueDateStr,
      type: json['type'] as String?,
    );
  }
}

class PlannerTask {
  final String id;
  final String title;
  final String course;
  final String duration;
  final bool completed;
  final String? dueDate;
  final String? difficulty;
  final String? status;

  PlannerTask({
    required this.id,
    required this.title,
    required this.course,
    required this.duration,
    required this.completed,
    this.dueDate,
    this.difficulty,
    this.status,
  });

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    String? dueDateStr;
    final d = json['dueDate'];
    if (d is String) dueDateStr = d;
    else if (d is List && d.length >= 3) dueDateStr = '${d[0]}-${d[1].toString().padLeft(2, '0')}-${d[2].toString().padLeft(2, '0')}';
    return PlannerTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      course: json['course'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      dueDate: dueDateStr,
      difficulty: json['difficulty'] as String?,
      status: json['status'] as String?,
    );
  }
}

class PlannerWeek {
  final String id;
  final String? weekStartDate;
  final String? weekEndDate;
  final int availableHours;

  PlannerWeek({
    required this.id,
    this.weekStartDate,
    this.weekEndDate,
    this.availableHours = 20,
  });

  factory PlannerWeek.fromJson(Map<String, dynamic> json) {
    return PlannerWeek(
      id: json['id'] as String? ?? '',
      weekStartDate: json['weekStartDate'] as String?,
      weekEndDate: json['weekEndDate'] as String?,
      availableHours: json['availableHours'] as int? ?? 20,
    );
  }
}

class WeeklySummary {
  final int tasksCompleted;
  final int totalTasks;
  final int overdueTasks;
  final int completionRatePercent;

  WeeklySummary({
    required this.tasksCompleted,
    required this.totalTasks,
    required this.overdueTasks,
    required this.completionRatePercent,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      totalTasks: json['totalTasks'] as int? ?? 0,
      overdueTasks: json['overdueTasks'] as int? ?? 0,
      completionRatePercent: json['completionRatePercent'] as int? ?? 0,
    );
  }
}
