import 'package:flutter/material.dart';
import 'weekly_checkin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool task1Completed = false;
  bool task2Completed = true;

  String _formattedDate() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Alert Banner
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
                    const Text(
                      'CS1234 Lab 1 due in 3 days',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14,
                        height: 1.43,
                        color: Color(0xFFC10007),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),

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
                        const Text("Today's Tasks", style: TextStyle(fontFamily: 'Arimo', fontSize: 16, height: 1.5, color: Color(0xFF101828), fontWeight: FontWeight.w400)),
                        const Text('1 of 2 completed', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TaskItemWidget(
                      isCompleted: task1Completed,
                      title: 'Review Chapter 5: Data Structures',
                      course: 'CS1234',
                      duration: '2 hours',
                      onChanged: (value) => setState(() => task1Completed = value ?? false),
                    ),
                    const SizedBox(height: 18),
                    TaskItemWidget(
                      isCompleted: task2Completed,
                      title: 'Practice Calculus Problems Set 3',
                      course: 'MA1101',
                      duration: '1 hour',
                      onChanged: (value) => setState(() => task2Completed = value ?? false),
                    ),
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
                    const Text('Actions', style: TextStyle(fontFamily: 'Arimo', fontSize: 16, height: 1.5, color: Color(0xFF101828), fontWeight: FontWeight.w400)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(color: const Color(0xFFAFBCDD), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Color(0xFFFFFFFF), size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Add Deadline', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFFFFFFFF), fontWeight: FontWeight.w400)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(color: const Color(0xFFC8CEDF), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_outlined, color: Color(0xFF364153), size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Edit Deadline', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF364153), fontWeight: FontWeight.w400)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyCheckInPage())),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        height: 36,
                        decoration: BoxDecoration(color: const Color(0xFF9C9EC3), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: Color(0xFFFFFFFF), size: 16),
                            const SizedBox(width: 8),
                            const Text('Weekly Check-In', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFFFFFFFF), fontWeight: FontWeight.w400)),
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
        ],
      ),
    );
  }
}

class TaskItemWidget extends StatelessWidget {
  final bool isCompleted;
  final String title;
  final String course;
  final String duration;
  final ValueChanged<bool?>? onChanged;

  const TaskItemWidget({
    Key? key,
    required this.isCompleted,
    required this.title,
    required this.course,
    required this.duration,
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
                border: Border.all(color: isCompleted ? const Color(0xFFAFBCDD) : const Color(0xFFD1D5DC), width: 2),
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
                    Text(course, style: const TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFFAFBCDD), fontWeight: FontWeight.w400)),
                    const SizedBox(width: 12),
                    const Text('•', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                    const SizedBox(width: 12),
                    Text(duration, style: const TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
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