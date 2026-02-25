import 'package:flutter/material.dart';
import 'api/group_api.dart';

/// Page 6.4 - AI Task Distribution
class TaskDistributionPage extends StatefulWidget {
  const TaskDistributionPage({Key? key}) : super(key: key);

  @override
  State<TaskDistributionPage> createState() => _TaskDistributionPageState();
}

class _TaskDistributionPageState extends State<TaskDistributionPage> {
  List<MemberDistribution> _distributions = [];
  List<GroupTask> _allTasks = [];
  bool _isLoading = true;
  bool _isRegenerating = false;
  bool _isDeletingAssignment = false;
  String _assignmentId = '';
  Map<String, dynamic>? _assignmentSetup;

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

  String _formatDeadline(dynamic deadline) {
    if (deadline == null) return 'No deadline';
    try {
      final date = deadline is String
          ? DateTime.parse(deadline)
          : deadline as DateTime;
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return 'Due ${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return 'No deadline';
    }
  }

  String _formatDependencies(String? depStr) {
    if (depStr == null || depStr.isEmpty) return 'None';
    try {
      final depId = int.parse(depStr);
      return 'Task $depId';
    } catch (_) {
      return depStr;
    }
  }

  int _memberNameSortKey(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 123;
    return trimmed.toUpperCase().codeUnitAt(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assignmentId.isEmpty) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _assignmentId = args?['assignmentId'] as String? ?? '';
      _loadDistribution();
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

  Future<void> _loadDistribution() async {
    setState(() => _isLoading = true);
    try {
      _assignmentId = await _resolveAssignmentIdIfMissing();
      if (_assignmentId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assignment found. Please create one first.'),
            backgroundColor: Color(0xFFE70030),
          ),
        );
        setState(() {
          _distributions = [];
          _allTasks = [];
          _assignmentSetup = null;
        });
        return;
      }

      final [distributions, tasks, setup] = await Future.wait<dynamic>([
        GroupApi.getTaskDistribution(_assignmentId),
        GroupApi.getTaskBreakdown(_assignmentId),
        GroupApi.getAssignmentSetup(_assignmentId),
      ]).timeout(const Duration(seconds: 90));

      final sortedDistributions = (distributions as List<MemberDistribution>)
        ..sort((a, b) {
          final keyCmp = _memberNameSortKey(
            a.name,
          ).compareTo(_memberNameSortKey(b.name));
          if (keyCmp != 0) return keyCmp;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      if (!mounted) return;
      setState(() {
        _distributions = sortedDistributions;
        _allTasks = tasks as List<GroupTask>;
        _assignmentSetup = setup as Map<String, dynamic>?;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load distribution: $e'),
          backgroundColor: const Color(0xFFE70030),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _regenerateDistribution() async {
    if (_isRegenerating) return;
    setState(() => _isRegenerating = true);
    try {
      final data = await GroupApi.regenerateDistribution(
        _assignmentId,
      ).timeout(const Duration(seconds: 35));
      if (!mounted) return;

      if (data.isEmpty) {
        final errorMessage =
            lastRegenerateDistributionError ??
            'Failed to regenerate distribution. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Color(0xFFE70030),
          ),
        );
        return;
      }

      data.sort((a, b) {
        final keyCmp = _memberNameSortKey(
          a.name,
        ).compareTo(_memberNameSortKey(b.name));
        if (keyCmp != 0) return keyCmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _distributions = data;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distribution regenerated.'),
          backgroundColor: Color(0xFF008236),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to regenerate distribution. Please try again.'),
          backgroundColor: Color(0xFFE70030),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  Future<void> _confirmDistribution() async {
    print('🔄 _confirmDistribution called');

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFFFFFFFF),
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Confirming distribution...'),
            ],
          ),
        ),
      ),
    );

    try {
      print('📤 Calling GroupApi.confirmDistribution($_assignmentId)');
      final success = await GroupApi.confirmDistribution(_assignmentId);
      print('📥 confirmDistribution returned: $success');

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (success) {
        print('✅ Confirmed successfully. Navigating to group overview...');
        // Navigate back to group overview
        Navigator.of(context).popUntil(
          (route) => route.settings.name == '/group-overview' || route.isFirst,
        );
      } else {
        print('❌ confirmDistribution failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to confirm distribution'),
            backgroundColor: Color(0xFFE70030),
          ),
        );
      }
    } catch (e) {
      print('❌ Exception in confirmDistribution: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE70030),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (_isDeletingAssignment) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFE70030),
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Delete Assignment',
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Are you sure you want to delete this assignment? This action cannot be undone.',
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 13,
                color: Color(0xFF6A7282),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A5565),
                    side: const BorderSide(color: Color(0xFFE7E6EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE70030),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isDeletingAssignment = true);

      try {
        final success = await GroupApi.deleteGroupAssignment(_assignmentId);
        if (mounted) {
          if (success) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete assignment'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting assignment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeletingAssignment = false);
        }
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
            onPressed: _isLoading ? null : _loadDistribution,
            tooltip: 'Refresh',
          ),
        ],
        centerTitle: true,
        title: const Text(
          'AI Task Distribution',
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header gradient card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFAFBCDD), Color(0xFFC8CEDF)],
                        ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox.shrink(),
                              GestureDetector(
                                onTap: _isDeletingAssignment
                                    ? null
                                    : () => _confirmDelete(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE70030,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isDeletingAssignment)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFFE70030),
                                                ),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.delete_outline,
                                          size: 13,
                                          color: Color(0xFFE70030),
                                        ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isDeletingAssignment
                                            ? 'Deleting...'
                                            : 'Delete',
                                        style: const TextStyle(
                                          fontFamily: 'Arimo',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFE70030),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _assignmentSetup?['courseCode'] ??
                                  _assignmentSetup?['courseName'] ??
                                  'Course',
                              style: const TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 12,
                                color: Color(0xFF2D4A7A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            _assignmentSetup?['assignmentTitle'] ??
                                'Assignment',
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              const Text(
                                'GROUP NAME:',
                                style: TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 11,
                                  color: Color(0xFF6A7282),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _assignmentSetup?['groupName'] ?? 'Group',
                                  style: const TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 12,
                                    color: Color(0xFF64709B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Color(0xFF364153),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatDeadline(
                                        _assignmentSetup?['deadline'],
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 12,
                                        color: Color(0xFF364153),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.assignment_outlined,
                                      size: 12,
                                      color: Color(0xFF364153),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${_distributions.fold(0, (sum, m) => sum + m.taskCount)} Tasks Total',
                                      style: const TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 12,
                                        color: Color(0xFF364153),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task Distribution',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/edit-setup',
                            arguments: {'assignmentId': _assignmentId},
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFAFBCDD),
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
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: Color(0xFFFFFFFF),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Edit Setup',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_distributions.isEmpty)
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
                              Icons.people_outline,
                              size: 40,
                              color: Color(0xFFAFBCDD),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No tasks distributed yet.',
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
                      ..._distributions.map(
                        (member) => _buildMemberSection(member),
                      ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmDistribution,
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
                              'Confirm',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isRegenerating
                                ? null
                                : _regenerateDistribution,
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
                                    'Regenerate Distribution',
                                    style: TextStyle(
                                      fontFamily: 'Arimo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
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

  Widget _buildMemberSection(MemberDistribution member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
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
                  child: Center(
                    child: Text(
                      member.initial,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF909EC3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.strengths.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 11,
                          color: Color(0xFF99A1AF),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE7E6EB),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${member.taskCount}',
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF364153),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: 0,
            ),
            child: Container(height: 1, color: const Color(0xFFE7E6EB)),
          ),

          if (member.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFAFBCDD).withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'No tasks assigned',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: member.tasks
                    .map<Widget>((task) => _buildTaskCard(task))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(MemberTask task) {
    final matchingTask = _allTasks.firstWhere(
      (t) => t.title == task.title,
      orElse: () => GroupTask(
        id: 0,
        title: task.title,
        description: '',
        effort: 'Medium',
      ),
    );
    final taskId = matchingTask.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFAFBCDD).withOpacity(0.10),
          width: 1,
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECFD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD0D9EE), width: 1),
                ),
                child: Center(
                  child: Text(
                    '$taskId',
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6A82B0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  // ── CHANGED: removed maxLines: 1 and overflow: ellipsis ──
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _effortBgColor(task.effort),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.effort,
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _effortColor(task.effort),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            task.description,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 12,
              color: Color(0xFF6A7282),
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBEDBFF), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: Color(0xFF5D7AA3),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    task.reason,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 12,
                      color: Color(0xFF5D7AA3),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
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
                    _formatDependencies(task.dependencies),
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
    );
  }
}
