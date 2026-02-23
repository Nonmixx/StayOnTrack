import 'package:flutter/material.dart';
import '../api/planner_api.dart';
import '../app_nav.dart';
import '../utils/calendar_utils.dart';
import '../weekly_checkin_page.dart';
import '../widgets/empty_state_card.dart';

class WeeklyPlannerPage extends StatefulWidget {
  final DateTime weekStartDate;

  const WeeklyPlannerPage({super.key, required this.weekStartDate});

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  List<PlannerTask> _tasks = [];
  List<Deadline> _deadlines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final weekStart = CalendarUtils.toIso(_normalizedWeekStart);
      var tasks = await PlannerApi.getWeekTasks(weekStart);
      final deadlines = await PlannerApi.getDeadlines();
      if (tasks.isEmpty && deadlines.isNotEmpty) {
        await PlannerApi.generatePlan(availableHours: 20);
        tasks = await PlannerApi.getWeekTasks(weekStart);
      }
      if (mounted) setState(() {
        _tasks = tasks;
        _deadlines = deadlines;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _tasks = [];
        _deadlines = [];
        _loading = false;
      });
    }
  }

  Future<void> _loadTasks() async => _loadData();

  Future<void> _toggleTask(String taskId, bool completed) async {
    final ok = await PlannerApi.toggleTaskCompletion(taskId, completed);
    if (ok && mounted) _loadTasks();
  }

  int get completedCount => _tasks.where((t) => t.completed).length;
  int get totalTasks => _tasks.length;

  DateTime get _normalizedWeekStart =>
      DateTime(widget.weekStartDate.year, widget.weekStartDate.month, widget.weekStartDate.day);

  @override
  Widget build(BuildContext context) {
    final start = _normalizedWeekStart;
    final weekLabel = '${CalendarUtils.formatShort(start)} - ${CalendarUtils.formatShort(start.add(const Duration(days: 6)))}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          weekLabel,
          style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFFAFBCDD),
        unselectedItemColor: const Color(0xFF99A1AF),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) AppNav.navigateToHome?.call();
          else if (index == 1) Navigator.pop(context);
          else if (index == 2) AppNav.navigateToGroup?.call();
          else if (index == 3) AppNav.navigateToSettings?.call();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 24), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined, size: 24), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 24), label: 'Group'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 24), label: 'Settings'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAFBCDD)))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Progress Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFAFBCDD), Color(0xFFC8CEDF)],
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
                              ],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Week Progress',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Color(0xFFFFFFFF),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(100),
                                        child: LinearProgressIndicator(
                                          value: totalTasks > 0 ? completedCount / totalTasks : 0,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          minHeight: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${totalTasks > 0 ? ((completedCount / totalTasks) * 100).toInt() : 0}%',
                                      style: const TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 16,
                                        height: 1.5,
                                        color: Color(0xFFFFFFFF),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedCount of $totalTasks tasks completed',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 14,
                                    height: 1.43,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Tasks by day
                          ..._tasksByDay().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: DailyTaskCard(
                                  day: e.key,
                                  date: _parseAndFormat(e.value.first.dueDate),
                                  tasks: e.value,
                                  onToggle: (taskId, completed) => _toggleTask(taskId, completed),
                                ),
                              )),
                          if (_tasks.isEmpty)
                            EmptyStateCard(
                              icon: Icons.calendar_today_outlined,
                              title: 'No study plan for this week',
                              subtitle: _deadlines.isEmpty
                                  ? 'Set up your plan in Settings first (add deadlines). You may add all your exams, assignments or any other tasks there.'
                                  : 'Complete the setup flow (Focus & Energy profile) to generate your AI study schedule. Or use Weekly Check-In to update your plan.',
                              buttonLabel: _deadlines.isEmpty ? 'Go to Settings' : 'Weekly Check-In',
                              onButtonTap: () {
                                if (_deadlines.isEmpty) {
                                  AppNav.goToSettings(context);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const WeeklyCheckInPage()),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Map<String, List<PlannerTask>> _tasksByDay() {
    final map = <String, List<PlannerTask>>{};
    for (final t in _tasks) {
      final day = t.dueDate != null ? _dayFromIso(t.dueDate!) : 'Unknown';
      map.putIfAbsent(day, () => []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        if (a.scheduledStartTime == null && b.scheduledStartTime == null) return 0;
        if (a.scheduledStartTime == null) return 1;
        if (b.scheduledStartTime == null) return -1;
        return a.scheduledStartTime!.compareTo(b.scheduledStartTime!);
      });
    }
    final order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final sorted = <String, List<PlannerTask>>{};
    for (final d in order) {
      if (map.containsKey(d)) sorted[d] = map[d]!;
    }
    for (final k in map.keys) {
      if (!sorted.containsKey(k)) sorted[k] = map[k]!;
    }
    return sorted;
  }

  String _dayFromIso(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length < 3) return 'Unknown';
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return CalendarUtils.weekdayName(d);
    } catch (_) {
      return 'Unknown';
    }
  }

  String _parseAndFormat(String? iso) {
    if (iso == null) return '';
    try {
      final parts = iso.split('-');
      if (parts.length < 3) return iso;
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return CalendarUtils.formatShort(d);
    } catch (_) {
      return iso;
    }
  }
}

class DailyTaskCard extends StatelessWidget {
  final String day;
  final String date;
  final List<PlannerTask> tasks;
  final void Function(String taskId, bool completed) onToggle;

  const DailyTaskCard({
    Key? key,
    required this.day,
    required this.date,
    required this.tasks,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.completed).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
        ],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF101828),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 14,
                      height: 1.43,
                      color: Color(0xFF6A7282),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Text(
                '$completed/${tasks.length}',
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 12,
                  height: 1.33,
                  color: Color(0xFF6A7282),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onToggle(t.id, !t.completed),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.only(left: 16.8, right: 16.8, top: 16.8, bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFAFBCDD).withOpacity(0.1), width: 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.completed ? const Color(0xFFAFBCDD) : const Color(0xFFD1D5DC),
                              width: 2,
                            ),
                            color: t.completed ? const Color(0xFFAFBCDD) : Colors.transparent,
                          ),
                          child: t.completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 16,
                                  height: 1.5,
                                  color: t.completed ? const Color(0xFF99A1AF) : const Color(0xFF101828),
                                  fontWeight: FontWeight.w400,
                                  decoration: t.completed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (t.timeSlotDisplay != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  t.timeSlotDisplay!,
                                  style: const TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 12,
                                    height: 1.33,
                                    color: Color(0xFF7E93CC),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    t.course,
                                    style: const TextStyle(
                                      fontFamily: 'Arimo',
                                      fontSize: 14,
                                      height: 1.43,
                                      color: Color(0xFFAFBCDD),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('•', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, color: Color(0xFF6A7282))),
                                  const SizedBox(width: 12),
                                  Text(
                                    t.duration,
                                    style: const TextStyle(
                                      fontFamily: 'Arimo',
                                      fontSize: 14,
                                      height: 1.43,
                                      color: Color(0xFF6A7282),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
