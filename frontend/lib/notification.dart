import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_session.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool _emailNotification   = false;
  bool _pushNotifications   = false;
  bool _deadlineAlerts      = false;
  bool _weeklyProgressReport = false;
  bool _isLoading = true;

  // Per-user key prefix using UID (more reliable than email)
  String get _prefix => 'notif_${UserSession.uid ?? 'guest'}_';

  String get _keyEmail    => '${_prefix}email';
  String get _keyPush     => '${_prefix}push';
  String get _keyDeadline => '${_prefix}deadline';
  String get _keyWeekly   => '${_prefix}weekly';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _emailNotification    = prefs.getBool(_keyEmail)    ?? false;
          _pushNotifications    = prefs.getBool(_keyPush)     ?? false;
          _deadlineAlerts       = prefs.getBool(_keyDeadline) ?? false;
          _weeklyProgressReport = prefs.getBool(_keyWeekly)   ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEmail,    _emailNotification);
      await prefs.setBool(_keyPush,     _pushNotifications);
      await prefs.setBool(_keyDeadline, _deadlineAlerts);
      await prefs.setBool(_keyWeekly,   _weeklyProgressReport);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  void _onToggleChanged(String key, bool val) {
    setState(() {
      if (key == _keyEmail)    _emailNotification    = val;
      if (key == _keyPush)     _pushNotifications    = val;
      if (key == _keyDeadline) _deadlineAlerts       = val;
      if (key == _keyWeekly)   _weeklyProgressReport = val;
    });
    _savePreferences();
  }

  TextStyle _arimo(double size,
      {Color color = Colors.black,
        FontWeight weight = FontWeight.normal}) =>
      GoogleFonts.arimo(fontSize: size, color: color, fontWeight: weight);

  @override
  Widget build(BuildContext context) {
    const cream    = Color(0xFFF5F0EB);
    const lavender = Color(0xFFE6CFE6);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: cream,
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Image.asset('assets/images/notification_icon.png',
                    width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Text('Manage how you receive notifications',
                    style: _arimo(16)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: lavender.withOpacity(0.80),
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF9C9EC3)))
                  : Column(
                children: [
                  _buildToggleItem(
                    title: 'Email Notification',
                    subtitle: 'Receive updates via email',
                    value: _emailNotification,
                    onChanged: (val) =>
                        _onToggleChanged(_keyEmail, val),
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Push Notifications',
                    subtitle: 'Get push notifications on your device',
                    value: _pushNotifications,
                    onChanged: (val) =>
                        _onToggleChanged(_keyPush, val),
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Deadline Alerts',
                    subtitle: 'Alerts for upcoming deadlines',
                    value: _deadlineAlerts,
                    onChanged: (val) =>
                        _onToggleChanged(_keyDeadline, val),
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Weekly Progress Report',
                    subtitle: 'Receive weekly progress summaries',
                    value: _weeklyProgressReport,
                    onChanged: (val) =>
                        _onToggleChanged(_keyWeekly, val),
                  ),
                  _buildDivider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: _arimo(14, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: _arimo(12, color: Colors.black54)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF9C9EC3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.black26,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    thickness: 0.5,
    indent: 20,
    endIndent: 20,
    color: Colors.black26,
  );
}