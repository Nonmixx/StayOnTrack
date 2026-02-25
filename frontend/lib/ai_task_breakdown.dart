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
  bool _isRegenerating = false;
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

  String _formatDependencies(String? depStr, {int? currentTaskId}) {
    if (depStr == null || depStr.trim().isEmpty) return 'None';

    final idByTitle = <String, int>{
      for (final task in _tasks) task.title.trim().toLowerCase(): task.id,
      for (final task in _tasks) _normalizeDependencyKey(task.title): task.id,
    };
    final segments = depStr
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (segments.isEmpty) return 'None';

    final formatted = <String>[];
    for (final segment in segments) {
      int? depId = int.tryParse(segment);
      depId ??= _extractFirstPositiveInt(segment);
      if (depId != null) {
        if (currentTaskId == null || depId != currentTaskId) {
          formatted.add('Task $depId');
        }
        continue;
      }

      final lower = segment.toLowerCase();
      final normalized = _normalizeDependencyKey(segment);
      final mappedId = idByTitle[lower] ?? idByTitle[normalized];
      if (mappedId != null) {
        if (currentTaskId == null || mappedId != currentTaskId) {
          formatted.add('Task $mappedId');
        }
        continue;
      }

      if (normalized.isNotEmpty) {
        for (final entry in idByTitle.entries) {
          final key = entry.key;
          if (key.isEmpty) continue;
          if (normalized.contains(key) || key.contains(normalized)) {
            if (currentTaskId == null || entry.value != currentTaskId) {
              formatted.add('Task ${entry.value}');
            }
            break;
          }
        }
      }
    }

    if (formatted.isEmpty) return 'None';
    return formatted.join(', ');
  }

  String _normalizeDependencyKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  int? _extractFirstPositiveInt(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    if (match == null) return null;
    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
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

  Future<String> _resolveAssignmentIdIfMissing() async {
    if (_assignmentId.isNotEmpty) return _assignmentId;

    final assignments = await GroupApi.getGroupAssignments();
    if (assignments.isEmpty) return '';

    assignments.sort((a, b) {
      DateTime parseOrMax(String raw) {
        try {
          return DateTime.parse(raw);
        } catch (_) {
          return DateTime(9999, 12, 31, 23, 59, 59);
        }
      }

      return parseOrMax(a.deadline).compareTo(parseOrMax(b.deadline));
    });

    return assignments.first.id;
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    _assignmentId = await _resolveAssignmentIdIfMissing();
    if (_assignmentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assignment found. Please create one first.'),
            backgroundColor: Color(0xFFE70030),
          ),
        );
      }
      setState(() {
        _tasks = [];
        _isLoading = false;
      });
      return;
    }

    final tasks = await GroupApi.getTaskBreakdown(_assignmentId);
    tasks.sort((a, b) => a.id.compareTo(b.id));
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _regenerateTasks() async {
    if (_isRegenerating) return;
    setState(() => _isRegenerating = true);
    try {
      final tasks = await GroupApi.regenerateTasks(_assignmentId);
      tasks.sort((a, b) => a.id.compareTo(b.id));
      final error = lastRegenerateTasksError;

      if (!mounted) return;
      if (tasks.isNotEmpty) {
        setState(() => _tasks = tasks);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasks regenerated.'),
            backgroundColor: Color(0xFF008236),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFE70030),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regenerate failed. Please try again.'),
            backgroundColor: Color(0xFFE70030),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Regenerate failed: $e'),
          backgroundColor: const Color(0xFFE70030),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D2D3A), size: 22),
            onPressed: _isLoading ? null : _loadTasks,
            tooltip: 'Refresh',
          ),
        ],
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
                            onPressed: _isRegenerating
                                ? null
                                : _regenerateTasks,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C9EC3),
                              foregroundColor: const Color(0xFFFFFFFF),
                              disabledBackgroundColor: const Color(0xFFD4D6E8),
                              disabledForegroundColor: const Color(0xFFFFFFFF),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isRegenerating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
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
                    // ── CHANGED: removed maxLines: 1 and overflow: ellipsis ──
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
                      _formatDependencies(
                        task.dependencies,
                        currentTaskId: task.id,
                      ),
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
