import 'package:flutter/material.dart';
import 'home_page.dart';
import 'planner_page.dart';
import 'monthly_planner_page.dart';
import 'weekly_planner_page.dart';
import 'weekly_checkin_page.dart';
import 'group_overview.dart';
import 'assignment_setup.dart';
import 'ai_task_breakdown.dart';
import 'ai_task_distribution.dart';
import 'edit_setup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayOnTrack AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigation(),

      routes: {
        '/group-overview': (context) => const GroupPage(),
        '/group-assignment-setup': (context) => const AssignmentSetupPage(),
        '/task-breakdown': (context) => const TaskBreakdownPage(),
        '/task-distribution': (context) => const TaskDistributionPage(),
        '/edit-setup': (context) => const EditSetupPage(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PlannerPage(),
    const GroupPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFAFBCDD),
        unselectedItemColor: const Color(0xFF99A1AF),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined, size: 24),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, size: 24),
            label: 'Group',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 24),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: const Center(child: Text('Settings Page')),
    );
  }
}
