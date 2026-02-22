import 'package:flutter/material.dart';

/// Settings page - user sets up their plan here (deadlines, semester, etc.).
/// Member 1's Add Deadline / setup flow will be linked from here.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Set up your plan in Settings first (add deadlines). You may add all your exams, assignments or any other tasks there.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6A7282),
            ),
          ),
        ),
      ),
    );
  }
}
