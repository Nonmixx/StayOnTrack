import 'package:flutter/material.dart';
import 'api/group_api.dart';
import 'package:intl/intl.dart';

/// Page 6.1 - Group Overview
class GroupPage extends StatefulWidget {
  const GroupPage({Key? key}) : super(key: key);

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List<GroupAssignment> _assignments = [];
  bool _isLoading = true;
  final Set<String> _deletingAssignmentIds = <String>{};
  bool _suppressNextCardTap = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    final data = await GroupApi.getGroupAssignments();
    data.sort((a, b) {
      final aDeadline = _parseDeadlineOrMax(a.deadline);
      final bDeadline = _parseDeadlineOrMax(b.deadline);
      return aDeadline.compareTo(bDeadline);
    });
    setState(() {
      _assignments = data;
      _isLoading = false;
    });
  }

  DateTime _parseDeadlineOrMax(String deadline) {
    try {
      return DateTime.parse(deadline);
    } catch (_) {
      return DateTime(9999, 12, 31, 23, 59, 59);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final assignment = _assignments[index];
    if (_deletingAssignmentIds.contains(assignment.id)) return;

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
            Text(
              'Are you sure you want to delete "${assignment.assignmentTitle}"? This action cannot be undone.',
              style: const TextStyle(
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
    if (confirmed == true) {
      GroupAssignment? removedAssignment;
      int removedIndex = -1;

      setState(() {
        _deletingAssignmentIds.add(assignment.id);
        removedIndex = _assignments.indexWhere((item) => item.id == assignment.id);
        if (removedIndex >= 0) {
          removedAssignment = _assignments.removeAt(removedIndex);
        }
      });

      try {
        final ok = await GroupApi.deleteGroupAssignment(assignment.id);
        if (!mounted) return;

        if (!ok) {
          setState(() {
            if (removedAssignment != null) {
              final insertIndex = removedIndex < 0
                  ? _assignments.length
                  : (removedIndex > _assignments.length ? _assignments.length : removedIndex);
              _assignments.insert(insertIndex, removedAssignment!);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete assignment. Please try again.'),
              backgroundColor: Color(0xFFE70030),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _deletingAssignmentIds.remove(assignment.id));
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Group',
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                          const Text(
                            'Group Assignments',
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_assignments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No group assignments yet.',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 14,
                                    color: Color(0xFF99A1AF),
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._assignments
                                .asMap()
                                .entries
                                .expand(
                                  (entry) => [
                                    _buildGroupCard(
                                      context: context,
                                      index: entry.key,
                                      assignment: entry.value,
                                    ),
                                    if (entry.key < _assignments.length - 1)
                                      const SizedBox(height: 16),
                                  ],
                                )
                                .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            '/group-assignment-setup',
                          );
                          _loadAssignments();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAFBCDD),
                          foregroundColor: const Color(0xFFFFFFFF),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '+ New Group Assignment',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required int index,
    required GroupAssignment assignment,
  }) {
    String formattedDeadline = '';
    try {
      final dt = DateTime.parse(assignment.deadline);
      formattedDeadline = DateFormat('yyyy-MM-dd hh:mm a').format(dt);
    } catch (_) {
      formattedDeadline = assignment.deadline;
    }

    final sortedInitials = [...assignment.memberInitials]
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
    final isDeleting = _deletingAssignmentIds.contains(assignment.id);

    return GestureDetector(
      onTap: isDeleting
          ? null
          : () async {
        if (_suppressNextCardTap) {
          _suppressNextCardTap = false;
          return;
        }
        await Navigator.pushNamed(
          context,
          '/task-distribution',
          arguments: {'assignmentId': assignment.id},
        );
        _loadAssignments();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course code (if exists)
                  if (assignment.courseCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 80),
                      child: Text(
                        assignment.courseCode,
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 12,
                          color: Color(0xFF9CB3CC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Group Name pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      assignment.groupName,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 13,
                        color: Color(0xFF4A5565),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Assignment Title
                  Text(
                    assignment.assignmentTitle,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Deadline
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Color(0xFF99A1AF),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedDeadline,
                        style: const TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 12,
                          color: Color(0xFF99A1AF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Member avatars + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 34,
                        width: sortedInitials.length * 28.0,
                        child: Stack(
                          children: [
                            for (int i = 0; i < sortedInitials.length; i++)
                              Positioned(
                                left: i * 22.0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      sortedInitials[i],
                                      style: const TextStyle(
                                        fontFamily: 'Arimo',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFAFBCDD),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFBCDD),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFAFBCDD).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button fixed at top-right inside card
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _suppressNextCardTap = true,
                onTap: isDeleting ? null : () => _confirmDelete(context, index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE70030).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDeleting)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE70030)),
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
                        isDeleting ? 'Deleting...' : 'Delete',
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
            ),
          ],
        ),
      ),
    );
  }
}
