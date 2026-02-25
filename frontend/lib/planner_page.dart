import 'package:flutter/material.dart';
import 'app_nav.dart';
import 'monthly_planner_page.dart';
import 'utils/calendar_utils.dart';
import 'api/planner_api.dart';
import 'data/deadline_store.dart';
import 'widgets/empty_state_card.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, this.refreshTrigger = 0});
  final int refreshTrigger;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  List<Deadline> _deadlines = [];
  bool _loading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadDeadlines();
    deadlineStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    deadlineStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) _loadDeadlines();
  }

  @override
  void didUpdateWidget(PlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) _loadDeadlines();
  }

  Future<void> _generatePlan() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final plan = await PlannerApi.generatePlan(availableHours: 20);
      if (plan != null) AppNav.onPlanRegenerated?.call();
      if (mounted) {
        if (plan != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan generated successfully!'), backgroundColor: Colors.green),
          );
          _loadDeadlines();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate plan. Ensure backend is running.'), backgroundColor: Colors.orange),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _loadDeadlines() async {
    try {
      final list = await PlannerApi.getDeadlines();
      if (mounted) setState(() {
        _deadlines = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _deadlines = [];
        _loading = false;
      });
    }
  }

  int _deadlinesInMonth(DateTime month) {
    return _deadlines.where((d) {
      if (d.dueDate == null) return false;
      final parts = d.dueDate!.split('-');
      if (parts.length < 2) return false;
      final dMonth = int.tryParse(parts[1]);
      final dYear = int.tryParse(parts[0]);
      return dMonth == month.month && dYear == month.year;
    }).length;
  }

  String _monthSummary(DateTime month) {
    final count = _deadlinesInMonth(month);
    if (count == 0) return 'No deadlines';
    return '$count deadline${count > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final months = CalendarUtils.plannerMonths();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Planner',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAFBCDD)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_deadlines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EmptyStateCard(
                          icon: Icons.event_note_outlined,
                          title: 'No deadlines yet',
                          subtitle: 'Set up your plan in Settings first (add deadlines). You may add all your exams, assignments or any other tasks there.',
                          buttonLabel: 'Go to Settings',
                          onButtonTap: () => AppNav.goToSettings(context),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isGenerating ? null : _generatePlan,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 18),
                            label: Text(_isGenerating ? 'Generating...' : 'Generate Plan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7E93CC),
                              side: const BorderSide(color: Color(0xFFAFBCDD)),
                            ),
                          ),
                        ),
                      ),
                    ...months.map((month) {
                    final isPast = CalendarUtils.isPastMonth(month);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MonthCard(
                        month: CalendarUtils.monthName(month.month),
                        abbreviation: CalendarUtils.monthAbbrev(month.month),
                        color: const Color(0xFFAFBCDD),
                        itemCount: _monthSummary(month),
                        isPast: isPast,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MonthlyPlannerPage(month: month),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  ],
                ),
              ),
            ),
    );
  }
}

class MonthCard extends StatelessWidget {
  final String month;
  final String abbreviation;
  final Color color;
  final String itemCount;
  final bool isPast;
  final VoidCallback onTap;

  const MonthCard({
    Key? key,
    required this.month,
    required this.abbreviation,
    required this.color,
    required this.itemCount,
    this.isPast = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final opacity = isPast ? 0.5 : 1.0;
    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 17.6, right: 17.6, top: 17.6, bottom: 1.6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            border: Border.all(color: const Color(0xFF7BF1A8), width: 1.6),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
            ],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        abbreviation,
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      month,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF101828),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF99A1AF), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9C9EC3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    itemCount,
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
