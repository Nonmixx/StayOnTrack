import 'package:flutter/material.dart';
import 'weekly_planner_page.dart';
import 'utils/calendar_utils.dart';
import 'api/planner_api.dart';

class MonthlyPlannerPage extends StatefulWidget {
  final DateTime month;

  const MonthlyPlannerPage({super.key, required this.month});

  @override
  State<MonthlyPlannerPage> createState() => _MonthlyPlannerPageState();
}

class _MonthlyPlannerPageState extends State<MonthlyPlannerPage> {
  List<Deadline> _deadlines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeadlines();
  }

  Future<void> _loadDeadlines() async {
    final list = await PlannerApi.getDeadlines();
    if (mounted) setState(() {
      _deadlines = list;
      _loading = false;
    });
  }

  int _examsInMonth() => _deadlines.where((d) {
    final t = (d.type ?? '').toLowerCase();
    return (t.contains('exam') || t.contains('midterm') || t.contains('final') || t.contains('quiz')) &&
        _inMonth(d.dueDate);
  }).length;

  int _assignmentsInMonth() => _deadlines.where((d) {
    final t = (d.type ?? '').toLowerCase();
    return (t.contains('assignment') || t.contains('lab') || t.contains('project') || t == '') && _inMonth(d.dueDate);
  }).length;

  bool _inMonth(String? dueDate) {
    if (dueDate == null) return false;
    final parts = dueDate.split('-');
    if (parts.length < 2) return false;
    final dMonth = int.tryParse(parts[1]);
    final dYear = int.tryParse(parts[0]);
    return dMonth == widget.month.month && dYear == widget.month.year;
  }

  @override
  Widget build(BuildContext context) {
    final grid = CalendarUtils.buildMonthGrid(widget.month);
    final monthLabel = '${CalendarUtils.monthName(widget.month.month)} ${widget.month.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D3A), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          monthLabel,
          style: const TextStyle(
            fontFamily: 'Arimo',
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF101828),
            fontWeight: FontWeight.w400,
          ),
        ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calendar grid
                          Container(
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
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: CalendarUtils.weekdayNames
                                      .map((day) => SizedBox(
                                            width: 40,
                                            child: Text(
                                              day,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontFamily: 'Arimo',
                                                fontSize: 12,
                                                height: 1.33,
                                                color: Color(0xFF6A7282),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                ...grid.map((week) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: List.generate(7, (i) {
                                          final cell = week[i];
                                          if (cell == null) return const SizedBox(width: 48, height: 48);
                                          final isToday = _isToday(cell);
                                          final isCurrentMonth = CalendarUtils.isInMonth(widget.month, cell);
                                          return CalendarDay(
                                            date: cell,
                                            isSelected: isToday,
                                            isHighlighted: false,
                                            isCurrentMonth: isCurrentMonth,
                                            onTap: () {
                                              final weekStart = _normalizeWeekStart(CalendarUtils.weekStart(cell));
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WeeklyPlannerPage(weekStartDate: weekStart),
                                                ),
                                              );
                                            },
                                          );
                                        }),
                                      ),
                                    )),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Week View',
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF101828),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildWeekCards(),
                          const SizedBox(height: 16),
                          // Workload Summary
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
                                  'Workload Summary',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Color(0xFFFFFFFF),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildSummaryRow('Exams this month', '${_examsInMonth()}'),
                                _buildSummaryRow('Assignments due', '${_assignmentsInMonth()}'),
                                const SizedBox(height: 16),
                              ],
                            ),
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

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  DateTime _normalizeWeekStart(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Widget> _buildWeekCards() {
    final weeks = <Widget>[];
    final first = CalendarUtils.firstOfMonth(widget.month);
    // Only show weeks whose Monday falls within this month (no overlap with adjacent months)
    var weekStart = _firstMondayInMonth(widget.month);
    var weekNum = 1;

    while (weekStart.month == widget.month.month && weekStart.year == widget.month.year) {
      final title = _getWeekTitle(weekStart);
      final normalized = _normalizeWeekStart(weekStart);
      weeks.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: WeekCard(
          weekNumber: weekNum,
          title: title,
          weekStartDate: normalized,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeeklyPlannerPage(weekStartDate: normalized),
            ),
          ),
        ),
      ));
      weekNum++;
      weekStart = weekStart.add(const Duration(days: 7));
    }

    return weeks.isEmpty
        ? [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WeekCard(
                weekNumber: 1,
                title: 'No tasks scheduled',
                weekStartDate: _normalizeWeekStart(CalendarUtils.weekStart(first)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyPlannerPage(weekStartDate: _normalizeWeekStart(CalendarUtils.weekStart(first))),
                  ),
                ),
              ),
            ),
          ]
        : weeks;
  }

  DateTime _firstMondayInMonth(DateTime month) {
    final first = CalendarUtils.firstOfMonth(month);
    final ws = CalendarUtils.weekStart(first);
    if (ws.month == month.month && ws.year == month.year) return ws;
    return ws.add(const Duration(days: 7));
  }

  String _getWeekTitle(DateTime weekStart) {
    final deadlines = _deadlines.where((d) {
      if (d.dueDate == null) return false;
      try {
        final parts = d.dueDate!.split('-');
        if (parts.length < 3) return false;
        final dDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return !dDate.isBefore(weekStart) && !dDate.isAfter(weekEnd);
      } catch (_) {
        return false;
      }
    }).toList();
    if (deadlines.isEmpty) return 'Study week';
    return deadlines.map((d) => d.title).take(2).join(', ');
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              height: 1.43,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              height: 1.43,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isHighlighted;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const CalendarDay({
    Key? key,
    required this.date,
    required this.isSelected,
    required this.isHighlighted,
    required this.isCurrentMonth,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: const Color(0xFFAFBCDD).withOpacity(0.3),
      highlightColor: const Color(0xFFAFBCDD).withOpacity(0.1),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAFBCDD).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              height: 1.43,
              color: isCurrentMonth ? const Color(0xFF4A5565) : const Color(0xFF99A1AF),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class WeekCard extends StatelessWidget {
  final int weekNumber;
  final String title;
  final DateTime weekStartDate;
  final VoidCallback onTap;

  const WeekCard({
    Key? key,
    required this.weekNumber,
    required this.title,
    required this.weekStartDate,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFE7E6EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week $weekNumber (${CalendarUtils.formatShort(weekStartDate)} - ${CalendarUtils.formatShort(weekStartDate.add(const Duration(days: 6)))})',
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF101828),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 14,
                      height: 1.43,
                      color: Color(0xFF4A5565),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF99A1AF), size: 16),
          ],
        ),
      ),
    );
  }
}
