import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Backend URL. 10.0.2.2 = Android emulator; localhost = web/desktop.
String get baseUrl => kIsWeb ? 'http://localhost:9091' : 'http://10.0.2.2:9091';

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
  /// Returns null on failure. Check res.statusCode for debugging.
  static Future<PlannerWeek?> generatePlan({int availableHours = 20}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/planner/generate?userId=$_userId&availableHours=$availableHours'),
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) return null;
      return PlannerWeek.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Get planner task count for a month (for workload summary).
  static Future<int> getMonthTaskCount(int year, int month) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/planner/month-tasks?userId=$_userId&year=$year&month=$month'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return 0;
      return int.tryParse(res.body) ?? 0;
    } catch (_) {
      return 0;
    }
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

  /// Create a deadline (saves to Firebase via backend).
  static Future<Deadline?> createDeadline({
    required String title,
    required String course,
    required DateTime? dueDate,
    String type = 'assignment',
  }) async {
    try {
      final body = jsonEncode({
        'title': title,
        'course': course,
        'dueDate': dueDate != null
            ? '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}'
            : null,
        'type': type,
      });
      final res = await http.post(
        Uri.parse('$baseUrl/api/deadlines?userId=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return Deadline.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Update a deadline.
  static Future<Deadline?> updateDeadline({
    required String id,
    required String title,
    required String course,
    required DateTime? dueDate,
    String type = 'assignment',
  }) async {
    try {
      final body = jsonEncode({
        'title': title,
        'course': course,
        'dueDate': dueDate != null
            ? '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}'
            : null,
        'type': type,
      });
      final res = await http.put(
        Uri.parse('$baseUrl/api/deadlines/$id?userId=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return Deadline.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Delete a deadline.
  static Future<bool> deleteDeadline(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/deadlines/$id?userId=$_userId'),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
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
  final DateTime? scheduledStartTime;
  final String? difficulty;
  final String? status;

  PlannerTask({
    required this.id,
    required this.title,
    required this.course,
    required this.duration,
    required this.completed,
    this.dueDate,
    this.scheduledStartTime,
    this.difficulty,
    this.status,
  });

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    String? dueDateStr;
    final d = json['dueDate'];
    if (d is String) dueDateStr = d;
    else if (d is List && d.length >= 3) dueDateStr = '${d[0]}-${d[1].toString().padLeft(2, '0')}-${d[2].toString().padLeft(2, '0')}';
    DateTime? scheduledStart;
    final st = json['scheduledStartTime'];
    if (st != null) {
      if (st is String) scheduledStart = DateTime.tryParse(st);
      else if (st is List && st.length >= 5) {
        scheduledStart = DateTime(
          (st[0] as num).toInt(),
          (st[1] as num).toInt(),
          (st[2] as num).toInt(),
          (st[3] as num).toInt(),
          (st[4] as num).toInt(),
        );
      }
    }
    return PlannerTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      course: json['course'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      dueDate: dueDateStr,
      scheduledStartTime: scheduledStart,
      difficulty: json['difficulty'] as String?,
      status: json['status'] as String?,
    );
  }

  /// Format time slot for display, e.g. "3:00 PM – 5:00 PM".
  String? get timeSlotDisplay {
    if (scheduledStartTime == null) return null;
    final start = scheduledStartTime!;
    final end = _parseDurationToMinutes(duration);
    final endTime = start.add(Duration(minutes: end));
    return '${_formatTime(start)} – ${_formatTime(endTime)}';
  }

  static int _parseDurationToMinutes(String dur) {
    final lower = dur.toLowerCase();
    final h = RegExp(r'(\d+(?:\.\d+)?)\s*(?:hour|hours|h)').firstMatch(lower);
    final m = RegExp(r'(\d+)\s*(?:minute|minutes|min|m)').firstMatch(lower);
    int mins = 60;
    if (h != null) mins = (double.parse(h.group(1)!) * 60).round();
    if (m != null) mins = (h != null ? mins : 0) + int.parse(m.group(1)!);
    return mins;
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final am = h < 12;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour}:${m.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
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
