import 'package:flutter/material.dart';
import 'weekly_planner_page.dart';

class MonthlyPlannerPage extends StatefulWidget {
  final String month;

  const MonthlyPlannerPage({super.key, required this.month});

  @override
  State<MonthlyPlannerPage> createState() => _MonthlyPlannerPageState();
}

class _MonthlyPlannerPageState extends State<MonthlyPlannerPage> {
  int selectedDay = 12;

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'February 2026',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF101828),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Card
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
                    // Weekday headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((day) => Container(
                                width: 40.14,
                                padding: const EdgeInsets.symmetric(vertical: 8),
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
                    // Calendar grid
                    ...List.generate(5, (weekIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (dayIndex) {
                            int dayNumber = weekIndex * 7 + dayIndex - 5;
                            if (dayNumber < 1 || dayNumber > 28) {
                              return const SizedBox(width: 48, height: 48);
                            }
                            return CalendarDay(
                              day: dayNumber,
                              isSelected: false,
                              isHighlighted: false,
                              onTap: () {
                                setState(() => selectedDay = dayNumber);
                                // Calculate which week this day belongs to (1-4)
                                int weekNumber = ((dayNumber - 1) ~/ 7) + 1;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WeeklyPlannerPage(weekNumber: weekNumber),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Week View Section
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
              WeekCard(weekNumber: 1, title: 'Start revision for CS1234', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyPlannerPage(weekNumber: 1)))),
              const SizedBox(height: 8),
              WeekCard(weekNumber: 2, title: 'Complete Lab 1', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyPlannerPage(weekNumber: 2)))),
              const SizedBox(height: 8),
              WeekCard(weekNumber: 3, title: 'Mid-term preparation', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyPlannerPage(weekNumber: 3)))),
              const SizedBox(height: 8),
              WeekCard(weekNumber: 4, title: 'Review and practice', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyPlannerPage(weekNumber: 4)))),
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
                    _buildSummaryRow('Exams this month', '0'),
                    _buildSummaryRow('Assignments due', '2'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated study hours',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 14,
                            height: 1.43,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Text(
                          '45-50 hours',
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
  final int day;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;

  const CalendarDay({
    Key? key,
    required this.day,
    required this.isSelected,
    required this.isHighlighted,
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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              height: 1.43,
              color: Color(0xFF4A5565),
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
  final VoidCallback onTap;

  const WeekCard({
    Key? key,
    required this.weekNumber,
    required this.title,
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
                    'Week $weekNumber',
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