import 'dart:convert';
import 'package:http/http.dart' as http;

import 'planner_api.dart' show baseUrl;
import '../utils/calendar_utils.dart';
import 'package:flutter_stayontrack/user_session.dart';

class SemesterApi {
  static String get _userId => UserSession.uid ?? 'default-user';

  static Future<Semester?> createSemester({
    required String semesterName,
    required DateTime startDate,
    required DateTime endDate,
    String? studyMode,
    List<String>? restDays,
  }) async {
    try {
      final body = jsonEncode({
        'semesterName': semesterName,
        'startDate': CalendarUtils.toIso(startDate),
        'endDate': CalendarUtils.toIso(endDate),
        if (studyMode != null) 'studyMode': studyMode,
        if (restDays != null) 'restDays': restDays,
      });
      final res = await http.post(
        Uri.parse('$baseUrl/api/semesters?userId=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return Semester.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Update an existing semester (use when documentId was already saved from a previous create).
  static Future<Semester?> updateSemester({
    required String semesterId,
    required String semesterName,
    required DateTime startDate,
    required DateTime endDate,
    String? studyMode,
    List<String>? restDays,
  }) async {
    try {
      final body = jsonEncode({
        'semesterName': semesterName,
        'startDate': CalendarUtils.toIso(startDate),
        'endDate': CalendarUtils.toIso(endDate),
        if (studyMode != null) 'studyMode': studyMode,
        if (restDays != null) 'restDays': restDays,
      });
      final res = await http.put(
        Uri.parse('$baseUrl/api/semesters/$semesterId?userId=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return Semester.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Semester>> getSemesters() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/semesters?userId=$_userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Semester.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

class Semester {
  final String id;
  final String? semesterName;
  final String? startDate;
  final String? endDate;
  final String? studyMode;
  final List<String>? restDays;

  Semester({
    required this.id,
    this.semesterName,
    this.startDate,
    this.endDate,
    this.studyMode,
    this.restDays,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    final rest = json['restDays'];
    return Semester(
      id: json['id'] as String? ?? '',
      semesterName: json['semesterName'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      studyMode: json['studyMode'] as String?,
      restDays: rest is List ? (rest as List).map((e) => e.toString()).toList() : null,
    );
  }
}
