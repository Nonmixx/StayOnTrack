import 'package:flutter/material.dart';
import 'app_nav.dart';
import 'routes.dart';
import 'weekly_checkin_page.dart';
import 'api/planner_api.dart';
import 'utils/calendar_utils.dart';
import 'widgets/empty_state_card.dart';
import 'data/deadline_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PlannerTask> _tasks = [];
  Deadline? _nearestDeadline;
  bool _loading = true;
  final Set<String> _demoCompletedIds = {}; // completion for store-sourced tasks

  @override
  void initState() {
    super.initState();
    _loadData();
    deadlineStore.addListener(_onDeadlineStoreChanged);
  }

  @override
  void dispose() {
    deadlineStore.removeListener(_onDeadlineStoreChanged);
    super.dispose();
  }

  void _onDeadlineStoreChanged() {
    if (mounted) _loadData();
  }

  static String _storeTaskId(DeadlineItem item) {
    final due = item.dueDate?.millisecondsSinceEpoch ?? 0;
    return 'store-${item.courseName}|${item.title}|$due';
  }

  Future<void> _loadData() async {
    try {
      var tasks = await PlannerApi.getTodaysTasks();
      final deadlines = await PlannerApi.getDeadlines();
      if (tasks.isEmpty && deadlines.isNotEmpty) {
        await PlannerApi.generatePlan(availableHours: 20);
        tasks = await PlannerApi.getTodaysTasks();
      }
      Deadline? nearest;
      final now = DateTime.now();
      for (final d in deadlines) {
        if (d.dueDate == null) continue;
        try {
          final parts = d.dueDate!.split('-');
          if (parts.length < 3) continue;
          final due = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (due.isBefore(now)) continue;
          if (nearest == null) {
            nearest = d;
            continue;
          }
          final nearestParts = nearest.dueDate!.split('-');
          final nearestDue = DateTime(
            int.parse(nearestParts[0]),
            int.parse(nearestParts[1]),
            int.parse(nearestParts[2]),
          );
          if (due.isBefore(nearestDue)) nearest = d;
        } catch (_) {}
      }
      List<PlannerTask> displayTasks = tasks;
      // When API returns no deadlines, compute nearest from store
      if (nearest == null && deadlineStore.items.isNotEmpty) {
        DateTime? nearestDue;
        DeadlineItem? nearestItem;
        for (final item in deadlineStore.items) {
          if (item.dueDate == null) continue;
          final d = item.dueDate!;
          if (d.isBefore(DateTime(now.year, now.month, now.day))) continue;
          if (nearestDue == null || d.isBefore(nearestDue)) {
            nearestDue = d;
            nearestItem = item;
          }
        }
        if (nearestItem != null && nearestDue != null) {
          nearest = Deadline(
            id: _storeTaskId(nearestItem),
            title: nearestItem.title,
            course: nearestItem.courseName,
            dueDate: '${nearestDue.year}-${nearestDue.month.toString().padLeft(2, '0')}-${nearestDue.day.toString().padLeft(2, '0')}',
            type: null,
          );
        }
      }
      if (mounted) setState(() {
        _tasks = displayTasks;
        _nearestDeadline = nearest;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _tasks = [];
        _nearestDeadline = null;
        _loading = false;
      });
    }
  }

  Future<void> _toggleTask(String taskId, bool completed) async {
    if (taskId.startsWith('store-')) {
      setState(() {
        if (completed) {
          _demoCompletedIds.add(taskId);
        } else {
          _demoCompletedIds.remove(taskId);
        }
        _tasks = _tasks.map((t) {
          if (t.id == taskId) return PlannerTask(id: t.id, title: t.title, course: t.course, duration: t.duration, completed: completed, dueDate: t.dueDate, scheduledStartTime: t.scheduledStartTime, difficulty: t.difficulty, status: t.status);
          return t;
        }).toList();
      });
      return;
    }
    final ok = await PlannerApi.toggleTaskCompletion(taskId, completed);
    if (ok && mounted) _loadData();
  }

  void _showAddDeadlineExamChoice() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add new',
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF101828),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.addDeadline, arguments: {'fromHomeAdd': true});
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFBCDD).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFAFBCDD).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFBCDD).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFF7E93CC), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assignment / Task',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 16,
                                height: 1.5,
                                color: Color(0xFF101828),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Add homework, projects, or other tasks',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF6A7282),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF99A1AF), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.courseAndExamInput, arguments: {'fromHomeAdd': true});
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFBCDD).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFAFBCDD).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFBCDD).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.quiz_outlined, color: Color(0xFF7E93CC), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exam',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 16,
                                height: 1.5,
                                color: Color(0xFF101828),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Add midterms, finals, quizzes',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF6A7282),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF99A1AF), size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${CalendarUtils.weekdayName(now)}, ${CalendarUtils.monthName(now.month)} ${now.day}, ${now.year}';
  }

  String _daysUntil(String? dueDate) {
    if (dueDate == null) return '';
    try {
      final parts = dueDate.split('-');
      if (parts.length < 3) return '';
      final due = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff == 0) return 'due today';
      if (diff == 1) return 'due tomorrow';
      if (diff < 0) return 'overdue';
      return 'due in $diff days';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.completed).length;
    final totalCount = _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'StayOnTrack AI',
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF101828),
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              _formattedDate(),
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFAFBCDD),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner (nearest deadline)
                if (_nearestDeadline != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFFC9C9), width: 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFB2C36), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_nearestDeadline!.course} ${_nearestDeadline!.title} ${_daysUntil(_nearestDeadline!.dueDate)}',
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 14,
                              height: 1.43,
                              color: Color(0xFFC10007),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_nearestDeadline != null) const SizedBox(height: 23),

                // Today's Tasks Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
                    ],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Tasks",
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF101828),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _loading ? '...' : '$completedCount of $totalCount completed',
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
                      const SizedBox(height: 18),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: Color(0xFFAFBCDD)),
                          ),
                        )
                      else if (_tasks.isEmpty)
                        EmptyStateCard(
                          icon: Icons.check_circle_outline,
                          title: 'No study plan for today',
                          subtitle: _nearestDeadline != null
                              ? 'Complete the Focus & Energy profile setup to generate your AI study schedule with time slots.'
                              : 'Set up your plan in Settings first (add deadlines). You may add all your exams, assignments or any other tasks there.',
                          buttonLabel: _nearestDeadline != null ? 'Complete Setup' : 'Go to Settings',
                          onButtonTap: () {
                            if (_nearestDeadline != null) {
                              Navigator.of(context).pushNamed(AppRoutes.focusAndEnergyProfile);
                            } else {
                              AppNav.goToSettings(context);
                            }
                          },
                        )
                      else
                        ..._tasks.asMap().entries.map((e) {
                          final t = e.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: e.key < _tasks.length - 1 ? 18 : 0),
                            child: TaskItemWidget(
                              isCompleted: t.completed,
                              title: t.title,
                              course: t.course,
                              duration: t.duration,
                              timeSlot: t.timeSlotDisplay,
                              onChanged: (value) => _toggleTask(t.id, value ?? false),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 23),

                // Actions Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
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
                        'Actions',
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF101828),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _showAddDeadlineExamChoice,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFAFBCDD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Color(0xFFFFFFFF), size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Deadline/Exam',
                                      style: TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 14,
                                        height: 1.43,
                                        color: Color(0xFFFFFFFF),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.editDeadlines),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC8CEDF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_outlined, color: Color(0xFF364153), size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Edit Deadline/Exam',
                                      style: TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 14,
                                        height: 1.43,
                                        color: Color(0xFF364153),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WeeklyCheckInPage()),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C9EC3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, color: Color(0xFFFFFFFF), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Weekly Check-In',
                                style: TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 14,
                                  height: 1.43,
                                  color: Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskItemWidget extends StatelessWidget {
  final bool isCompleted;
  final String title;
  final String course;
  final String duration;
  final String? timeSlot;
  final ValueChanged<bool?>? onChanged;

  const TaskItemWidget({
    Key? key,
    required this.isCompleted,
    required this.title,
    required this.course,
    required this.duration,
    this.timeSlot,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16.8, right: 16.8, top: 16.8, bottom: 0.8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFAFBCDD).withOpacity(0.1), width: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onChanged?.call(!isCompleted),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? const Color(0xFFAFBCDD) : const Color(0xFFD1D5DC),
                  width: 2,
                ),
                color: isCompleted ? const Color(0xFFAFBCDD) : Colors.transparent,
              ),
              child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timeSlot != null) ...[
                  Text(
                    timeSlot!,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 12,
                      height: 1.33,
                      color: Color(0xFF7E93CC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 16,
                    height: 1.5,
                    color: isCompleted ? const Color(0xFF99A1AF) : const Color(0xFF101828),
                    fontWeight: FontWeight.w400,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      course,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14,
                        height: 1.43,
                        color: Color(0xFFAFBCDD),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('•', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                    const SizedBox(width: 12),
                    Text(
                      duration,
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
    );
  }
}
