import 'package:flutter/material.dart';

class WeeklyPlannerPage extends StatefulWidget {
  final int weekNumber;

  const WeeklyPlannerPage({super.key, required this.weekNumber});

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  final List<DayTask> tasks = [
    DayTask(day: 'Monday', date: 'Feb 12', task: 'Review lecture notes', course: 'CS1234', duration: '1.5 hours', completed: false),
    DayTask(day: 'Tuesday', date: 'Feb 13', task: 'Practice problems', course: 'MA1101', duration: '2 hours', completed: false),
    DayTask(day: 'Wednesday', date: 'Feb 14', task: 'Read textbook chapter', course: 'PH2001', duration: '1 hour', completed: false),
    DayTask(day: 'Thursday', date: 'Feb 15', task: 'Work on assignment', course: 'CS1234', duration: '3 hours', completed: true),
    DayTask(day: 'Friday', date: 'Feb 16', task: 'Revision session', course: 'MA1101', duration: '1.5 hours', completed: true),
  ];

  int get completedCount => tasks.where((t) => t.completed).length;
  int get totalTasks => tasks.length;

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
        title: Text(
          'Week ${widget.weekNumber}',
          style: const TextStyle(
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
                              value: completedCount / totalTasks,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${((completedCount / totalTasks) * 100).toInt()}%',
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

              // Daily tasks
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DailyTaskCard(
                      dayTask: tasks[index],
                      dayNumber: index + 1,
                      totalDays: tasks.length,
                      onToggle: () => setState(() => tasks[index].completed = !tasks[index].completed),
                    ),
                  );
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
}

class DayTask {
  final String day;
  final String date;
  final String task;
  final String course;
  final String duration;
  bool completed;

  DayTask({
    required this.day,
    required this.date,
    required this.task,
    required this.course,
    required this.duration,
    this.completed = false,
  });
}

class DailyTaskCard extends StatelessWidget {
  final DayTask dayTask;
  final int dayNumber;
  final int totalDays;
  final VoidCallback onToggle;

  const DailyTaskCard({
    Key? key,
    required this.dayTask,
    required this.dayNumber,
    required this.totalDays,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    dayTask.day,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF101828),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    dayTask.date,
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
                '${dayTask.completed ? 1 : 0}/1',
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
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Container(
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
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: dayTask.completed ? const Color(0xFFAFBCDD) : const Color(0xFFD1D5DC), width: 2),
                      color: dayTask.completed ? const Color(0xFFAFBCDD) : Colors.transparent,
                    ),
                    child: dayTask.completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayTask.task,
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 16,
                            height: 1.5,
                            color: dayTask.completed ? const Color(0xFF99A1AF) : const Color(0xFF101828),
                            fontWeight: FontWeight.w400,
                            decoration: dayTask.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(dayTask.course, style: const TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFFAFBCDD), fontWeight: FontWeight.w400)),
                            const SizedBox(width: 12),
                            const Text('•', style: TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                            const SizedBox(width: 12),
                            Text(dayTask.duration, style: const TextStyle(fontFamily: 'Arimo', fontSize: 14, height: 1.43, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}