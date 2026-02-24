import 'package:flutter/material.dart';
import 'api/group_api.dart';

/// Page 6.3 - AI Task Breakdown
class TaskBreakdownPage extends StatefulWidget {
  const TaskBreakdownPage({Key? key}) : super(key: key);

  @override
  State<TaskBreakdownPage> createState() => _TaskBreakdownPageState();
}

class _TaskBreakdownPageState extends State<TaskBreakdownPage> {
  List<GroupTask> _tasks = [];
  bool _isLoading = true;
  String _assignmentId = '';

  Color _effortColor(String effort) {
    switch (effort) {
      case 'Low':
        return const Color(0xFF008236);
      case 'High':
        return const Color(0xFFE70030);
      default:
        return const Color(0xFFD95700);
    }
  }

  Color _effortBgColor(String effort) {
    switch (effort) {
      case 'Low':
        return const Color(0xFFDBFCE7);
      case 'High':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFFFEFDA);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assignmentId.isEmpty) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _assignmentId = args?['assignmentId'] as String? ?? '';
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await GroupApi.getTaskBreakdown(_assignmentId);
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _regenerateTasks() async {
    setState(() => _isLoading = true);
    final tasks = await GroupApi.regenerateTasks(_assignmentId);
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2D2D3A),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'AI Task Breakdown',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFAFBCDD)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBEDBFF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF5D7AA3),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 13,
                                color: Color(0xFF5D7AA3),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Note: ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text:
                                      'These tasks were derived from the assignment brief.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Empty state
                  if (_tasks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 40,
                            color: Color(0xFFAFBCDD),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No tasks generated yet.',
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 14,
                              color: Color(0xFF99A1AF),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._tasks.map((task) => _buildTaskCard(task)),

                  const SizedBox(height: 8),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/task-distribution',
                              arguments: {'assignmentId': _assignmentId},
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC8CEDF),
                              foregroundColor: const Color(0xFF364153),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Distribute Tasks',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _regenerateTasks,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C9EC3),
                              foregroundColor: const Color(0xFFFFFFFF),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Regenerate Tasks',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
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
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) Navigator.popUntil(context, (route) => route.isFirst);
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

  Widget _buildTaskCard(GroupTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE7E6EB),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${task.id}',
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A7282),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              task.description,
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 13,
                color: Color(0xFF6A7282),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _effortBgColor(task.effort),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.effort,
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _effortColor(task.effort),
                ),
              ),
            ),

            if (task.dependencies != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Depends on: ',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 12,
                      color: Color(0xFF99A1AF),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3FB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFD0D9EE),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.dependencies!,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 12,
                        color: Color(0xFF6A82B0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Depends on: None',
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 12,
                  color: Color(0xFF99A1AF),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
