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
      _loadDistribution();
    }
  }

  Future<void> _loadDistribution() async {
    setState(() => _isLoading = true);
    final data = await GroupApi.getTaskDistribution(_assignmentId);
    setState(() {
      _distributions = data;
      _isLoading = false;
    });
  }

  Future<void> _regenerateDistribution() async {
    setState(() => _isLoading = true);
    final data = await GroupApi.regenerateDistribution(_assignmentId);
    setState(() {
      _distributions = data;
      _isLoading = false;
    });
  }

  // Confirm distribution → call API → return to Group Overview
  Future<void> _confirmDistribution() async {
    final success = await GroupApi.confirmDistribution(_assignmentId);
    if (success && mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
      Navigator.popUntil(context, (route) => route.isFirst);
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
                                onTap: () => _confirmDelete(context),
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
                                    children: const [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 13,
                                        color: Color(0xFFE70030),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
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
                            child: const Text(
                              'MKT305',
                              style: TextStyle(
                                fontFamily: 'Arimo',
                                fontSize: 12,
                                color: Color(0xFF2D4A7A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          const Text(
                            'Marketing Strategy Deck',
                            style: TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                              height: 1.2,
                            ),
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
                                child: const Text(
                                  'MarketMinds',
                                  style: TextStyle(
                                    fontFamily: 'Arimo',
                                    fontSize: 12,
                                    color: Color(0xFF64709B),
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  children: const [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Color(0xFF364153),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Due Wed, 15 Nov',
                                      style: TextStyle(
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
                                    // Show real task count from API data
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

                    // Task Distribution header + Edit Setup
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

                    // Empty state
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

                    // Bottom action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            // Calls API then navigates back to Group Overview
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
                            onPressed: _regenerateDistribution,
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
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 5),

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
                Text(
                  task.dependencies!,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A7282),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
