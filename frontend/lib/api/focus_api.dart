import 'dart:convert';
import 'package:http/http.dart' as http;

import 'planner_api.dart' show baseUrl;

class FocusApi {
  static String _userId = 'default-user';

  static void setUserId(String userId) => _userId = userId;

  static Future<FocusProfile?> createFocusProfile({
    required List<String> peakFocusTimes,
    required List<String> lowEnergyTimes,
    required String typicalStudyDuration,
  }) async {
    try {
      final body = jsonEncode({
        'peakFocusTimes': peakFocusTimes,
        'lowEnergyTimes': lowEnergyTimes,
        'typicalStudyDuration': typicalStudyDuration,
      });
      final res = await http.post(
        Uri.parse('$baseUrl/api/focus-profiles?userId=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return FocusProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<FocusProfile?> updateFocusProfile(String id, {
    required List<String> peakFocusTimes,
    required List<String> lowEnergyTimes,
    required String typicalStudyDuration,
  }) async {
    try {
      final body = jsonEncode({
        'peakFocusTimes': peakFocusTimes,
        'lowEnergyTimes': lowEnergyTimes,
        'typicalStudyDuration': typicalStudyDuration,
      });
      final res = await http.put(
        Uri.parse('$baseUrl/api/focus-profiles/$id?userId=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return FocusProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<FocusProfile>> getFocusProfiles() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/focus-profiles?userId=$_userId'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => FocusProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

class FocusProfile {
  final String id;
  final List<String>? peakFocusTimes;
  final List<String>? lowEnergyTimes;
  final String? typicalStudyDuration;

  FocusProfile({
    required this.id,
    this.peakFocusTimes,
    this.lowEnergyTimes,
    this.typicalStudyDuration,
  });

  factory FocusProfile.fromJson(Map<String, dynamic> json) {
    final peak = json['peakFocusTimes'];
    final low = json['lowEnergyTimes'];
    return FocusProfile(
      id: json['id'] as String? ?? '',
      peakFocusTimes: peak is List ? (peak as List).map((e) => e.toString()).toList() : null,
      lowEnergyTimes: low is List ? (low as List).map((e) => e.toString()).toList() : null,
      typicalStudyDuration: json['typicalStudyDuration'] as String?,
    );
  }
}
