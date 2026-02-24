import 'package:flutter/material.dart';
import 'app_nav.dart';
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
import 'settings_page.dart';
import 'semester_setup_page.dart';
import 'course_and_exam_input.dart';
import 'assignment_and_project_page.dart';
import 'focus_and_energy_profile_page.dart';
import 'add_deadline_page.dart';
import 'edit_deadlines_page.dart';
import 'routes.dart';

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
      home: const SemesterSetupPage(),
      routes: {
        AppRoutes.semesterSetup: (context) => const SemesterSetupPage(),
        AppRoutes.courseAndExamInput: (context) =>
            const CourseAndExamInputPage(),
        AppRoutes.assignmentAndProject: (context) =>
            const AssignmentAndProjectPage(),
        AppRoutes.focusAndEnergyProfile: (context) =>
            const FocusAndEnergyProfilePage(),
        AppRoutes.addDeadline: (context) {
          final a =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          if (a == null) return const AddDeadlinePage();
          return AddDeadlinePage(
            editIndex: a['editIndex'] as int?,
            editId: a['editId'] as String?,
            initialTitle: a['title'] as String?,
            initialCourse: a['courseName'] as String?,
            initialDueDate: a['dueDate'] as DateTime?,
            initialDifficulty: a['difficulty'] as String?,
            initialIsIndividual: a['isIndividual'] as bool?,
            initialType: a['editType'] as String?,
          );
        },
        AppRoutes.editDeadlines: (context) => const EditDeadlinesPage(),
        AppRoutes.home: (context) => const MainNavigation(),

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

  static const int _settingsIndex = 3;

  static const int _homeIndex = 0;
  static const int _plannerIndex = 1;
  static const int _groupIndex = 2;

  @override
  void initState() {
    super.initState();
    AppNav.navigateToHome = () => setState(() => _selectedIndex = _homeIndex);
    AppNav.navigateToPlanner = () =>
        setState(() => _selectedIndex = _plannerIndex);
    AppNav.navigateToGroup = () => setState(() => _selectedIndex = _groupIndex);
    AppNav.navigateToSettings = () =>
        setState(() => _selectedIndex = _settingsIndex);
  }

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
        backgroundColor: const Color(0xFFFFFFFF),
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
        centerTitle: true,
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
