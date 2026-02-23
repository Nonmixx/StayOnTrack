import 'package:flutter/material.dart';
import '../api/planner_api.dart';

class WeeklyCheckInPage extends StatefulWidget {
  const WeeklyCheckInPage({super.key});

  @override
  State<WeeklyCheckInPage> createState() => _WeeklyCheckInPageState();
}

class _WeeklyCheckInPageState extends State<WeeklyCheckInPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _workloadController = TextEditingController();
  bool _isLoading = false;
  WeeklySummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final s = await PlannerApi.getWeeklySummary();
    if (mounted) setState(() => _summary = s);
  }

  Future<void> _onRegenerate() async {
    final hours = int.tryParse(_workloadController.text) ?? 20;
    setState(() => _isLoading = true);
    try {
      final week = await PlannerApi.regenerateNextWeek(
        feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
        availableStudyHoursNextWeek: hours,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(week != null ? 'Weekly plan updated successfully!' : 'Failed to update plan. Is the backend running?'),
            backgroundColor: week != null ? Colors.green : Colors.red,
          ),
        );
        if (week != null) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _workloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Weekly Check-In',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
            children: [
              // Weekly Summary Card
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
                      children: [
                        const Icon(Icons.bar_chart, color: Color(0xFFAFBCDD), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Weekly Summary',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFF101828),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            title: 'Tasks Completed',
                            value: '${_summary?.tasksCompleted ?? 0}',
                            subtitle: '/${_summary?.totalTasks ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: _buildStatBox(
                            title: 'Completion Rate',
                            value: '${_summary?.completionRatePercent ?? 0}',
                            subtitle: '%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(left: 12.8, right: 12.8, top: 12.8, bottom: 0.8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFFC9C9), width: 0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overdue Tasks',
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 12,
                              height: 1.33,
                              color: Color(0xFFE7000B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_summary?.overdueTasks ?? 0} tasks',
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 20,
                              height: 1.4,
                              color: Color(0xFFC10007),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),

              // Feedback Section
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
                      'Adjust Next Week\'s Plan',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF101828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          height: 1.43,
                          color: Color(0xFF364153),
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(text: 'How was your week? '),
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: Color(0xFFC10007),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share any struggles, wins, or thoughts...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          height: 1.43,
                          color: Color(0xFF717182),
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFAFBCDD).withOpacity(0.3), width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFAFBCDD).withOpacity(0.3), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFAFBCDD), width: 0.8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this when you\'re not satisfied with your current plan. Your feedback and available hours will regenerate next week only.',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 12,
                        height: 1.33,
                        color: Color(0xFF6A7282),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          height: 1.43,
                          color: Color(0xFF364153),
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(text: 'Available study hours next week '),
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: Color(0xFFC10007),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _workloadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '20',
                        hintStyle: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          color: Color(0xFF717182),
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFAFBCDD).withOpacity(0.3), width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFAFBCDD).withOpacity(0.3), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFAFBCDD), width: 0.8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This helps us distribute your tasks realistically.',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 12,
                        height: 1.33,
                        color: Color(0xFF6A7282),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),

              // Update Button
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
                      'Ready to Update?',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI will adjust task intensity and redistribute workload for next week only.',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14,
                        height: 1.43,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _onRegenerate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        minimumSize: const Size(double.infinity, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFAFBCDD)),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, color: Color(0xFFAFBCDD), size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Regenerate Next Week Plan',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 14,
                                    height: 1.43,
                                    color: Color(0xFFAFBCDD),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 17),

              // Note
              Container(
                padding: const EdgeInsets.only(left: 12.8, right: 12.8, top: 12.8, bottom: 0.8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBEDBFF), width: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Note: Only next week\'s schedule will be updated. Current week and future weeks remain unchanged until you check in again.',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    height: 1.33,
                    color: Color(0xFF1447E6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFFAFBCDD),
        unselectedItemColor: const Color(0xFF99A1AF),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            // Navigate to Planner
            Navigator.popUntil(context, (route) => route.isFirst);
          }
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

  Widget _buildStatBox({required String title, required String value, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 12,
              height: 1.33,
              color: Color(0xFF6A7282),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 24,
                  height: 1.33,
                  color: Color(0xFF101828),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 24,
                  height: 1.33,
                  color: Color(0xFF101828),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}