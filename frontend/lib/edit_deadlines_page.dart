import 'package:flutter/material.dart';
import 'app_nav.dart';
import 'routes.dart';
import 'data/deadline_store.dart';

/// Manage Deadlines page. View, edit, or delete deadlines. Similar to Added Assignments layout.
/// List is driven by [deadlineStore] (shared with Add Deadline, exams, assignments).
class EditDeadlinesPage extends StatefulWidget {
  const EditDeadlinesPage({super.key});

  @override
  State<EditDeadlinesPage> createState() => _EditDeadlinesPageState();
}

class _EditDeadlinesPageState extends State<EditDeadlinesPage> {
  static const _pageBackground = Color(0xFFFFF8F0);
  static const _containerBg = Color(0xFFD6E0EF); // light blue-grey
  static const _sectionTitleGrey = Color(0xFF4A5568);

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    deadlineStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    deadlineStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  String _formatDateLong(DateTime? date) {
    if (date == null) return '';
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _onAddNew() {
    _showAddChoice(context);
  }

  void _showAddChoice(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add new',
                style: TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF101828),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.addDeadline);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFBCDD).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFAFBCDD).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFBCDD).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFF7E93CC), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assignment / Task', style: TextStyle(fontFamily: 'Arimo', fontSize: 16, height: 1.5, color: Color(0xFF101828), fontWeight: FontWeight.w500)),
                            SizedBox(height: 2),
                            Text('Add homework, projects, or other tasks', style: TextStyle(fontFamily: 'Arimo', fontSize: 13, height: 1.4, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF99A1AF), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.courseAndExamInput);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFBCDD).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFAFBCDD).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAFBCDD).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.quiz_outlined, color: Color(0xFF7E93CC), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exam', style: TextStyle(fontFamily: 'Arimo', fontSize: 16, height: 1.5, color: Color(0xFF101828), fontWeight: FontWeight.w500)),
                            SizedBox(height: 2),
                            Text('Add midterms, finals, quizzes', style: TextStyle(fontFamily: 'Arimo', fontSize: 13, height: 1.4, color: Color(0xFF6A7282), fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF99A1AF), size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(int index) {
    final entry = deadlineStore.items[index];
    Navigator.of(context).pushNamed(
      AppRoutes.addDeadline,
      arguments: <String, dynamic>{
        'editIndex': index,
        'title': entry.title,
        'courseName': entry.courseName,
        'dueDate': entry.dueDate,
        'difficulty': entry.difficulty,
        'isIndividual': entry.isIndividual,
      },
    );
  }

  void _onDelete(int index) {
    final title = deadlineStore.items[index].title;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete deadline?'),
        content: Text(
          'Remove "$title" from your deadlines?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              deadlineStore.removeAt(index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Deadlines',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _containerBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Deadlines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _sectionTitleGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (deadlineStore.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No deadlines yet. Tap "+ Add New" to add one.',
                          style: TextStyle(
                            color: Color(0xFF6A7282),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deadlineStore.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _DeadlineCard(
                        entry: deadlineStore.items[i],
                        formatDateLong: _formatDateLong,
                        onEdit: () => _onEdit(i),
                        onDelete: () => _onDelete(i),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton.icon(
                      onPressed: _onAddNew,
                      icon: const Icon(Icons.add, size: 20, color: Colors.black87),
                      label: const Text(
                        'Add New',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home, label: 'Home', onTap: () => _onBottomNavTap(0)),
                _NavItem(icon: Icons.calendar_today_outlined, label: 'Planner', onTap: () => _onBottomNavTap(1)),
                _NavItem(icon: Icons.people_outline, label: 'Group', onTap: () => _onBottomNavTap(2)),
                _NavItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => _onBottomNavTap(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    switch (index) {
      case 0:
        AppNav.navigateToHome?.call();
        break;
      case 1:
        AppNav.navigateToPlanner?.call();
        break;
      case 2:
        AppNav.navigateToGroup?.call();
        break;
      case 3:
        AppNav.navigateToSettings?.call();
        break;
    }
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({
    required this.entry,
    required this.formatDateLong,
    required this.onEdit,
    required this.onDelete,
  });

  final DeadlineItem entry;
  final String Function(DateTime?) formatDateLong;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _darkPurple = Color(0xFF4A5568);
  static const _detailGrey = Color(0xFF6A7282);
  static const _easyBg = Color(0xFFDCFCE7);
  static const _easyText = Color(0xFF166534);
  static const _mediumBg = Color(0xFFF0F6B0); // light yellow-green per image
  static const _mediumText = Color(0xFF854D0E);
  static const _hardBg = Color(0xFFFEE2E2);
  static const _hardText = Color(0xFF991B1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.radio_button_unchecked,
                size: 22,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _darkPurple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.courseName} • ${entry.isIndividual ? 'Individual' : 'Group'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _detailGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                _difficultyChip(entry.difficulty),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      formatDateLong(entry.dueDate),
                      style: const TextStyle(fontSize: 14, color: _detailGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade700),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade700),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _difficultyChip(String difficulty) {
    Color bg;
    Color textColor;
    switch (difficulty) {
      case 'Easy':
        bg = _easyBg;
        textColor = _easyText;
        break;
      case 'Hard':
        bg = _hardBg;
        textColor = _hardText;
        break;
      default:
        bg = _mediumBg;
        textColor = _mediumText;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const _navColor = Color(0xFF99A1AF);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: _navColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: _navColor),
            ),
          ],
        ),
      ),
    );
  }
}
