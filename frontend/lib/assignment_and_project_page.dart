import 'package:flutter/material.dart';
import 'app_nav.dart';
import 'routes.dart';
import 'api/planner_api.dart';
import 'data/deadline_store.dart';
import 'utils/calendar_utils.dart';

/// Assignments & Projects screen. Shown after Course and Exam Input (or via Skip to Assignments).
class AssignmentAndProjectPage extends StatefulWidget {
  const AssignmentAndProjectPage({super.key});

  @override
  State<AssignmentAndProjectPage> createState() => _AssignmentAndProjectPageState();
}

class _AssignmentAndProjectPageState extends State<AssignmentAndProjectPage> {
  final _courseNameController = TextEditingController();
  final _assignmentNameController = TextEditingController();
  DateTime? _deadline;
  String? _selectedDifficulty;
  bool _isIndividual = true;
  final List<_AssignmentEntry> _assignments = [];
  int? _editingIndex;

  // Same as course_and_exam_input_page: title = Exam Schedule, Skip = Skip to Assignments, Next = Next
  static const _titlePurple = Color(0xFF7E93CC);
  static const _skipButtonColor = Color(0xFFAFBCDD);
  static const _nextButtonColor = Color(0xFF9C9EC3);
  static const _darkPurple = Color(0xFF4A5568);
  static const _lightPurple = Color(0xFFB8C4E3);
  static const _pageBackground = Color(0xFFF5F0E8);
  static const _hintGray = Color(0xFF9CA3AF);

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _selectedDifficulty ??= _difficulties[1]; // Medium
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final list = await PlannerApi.getDeadlines();
    if (!mounted) return;
    final assignments = list
        .where((d) => d.type == 'assignment')
        .map((d) => _deadlineToAssignmentEntry(d))
        .toList();
    setState(() {
      _assignments.clear();
      _assignments.addAll(assignments);
    });
  }

  _AssignmentEntry _deadlineToAssignmentEntry(Deadline d) {
    return _AssignmentEntry(
      id: d.id,
      courseName: d.course,
      assignmentName: d.title,
      deadline: _parseDueDate(d.dueDate),
      difficulty: d.difficulty ?? 'Medium',
      isIndividual: d.isIndividual ?? true,
    );
  }

  static DateTime? _parseDueDate(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _assignmentNameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return CalendarUtils.formatDisplay(date);
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _formatDateLong(DateTime? date) {
    if (date == null) return '';
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _addAssignment() async {
    final course = _courseNameController.text.trim();
    final name = _assignmentNameController.text.trim();
    if (course.isEmpty || name.isEmpty) return;
    final entry = _AssignmentEntry(
      id: _editingIndex != null ? _assignments[_editingIndex!].id : null,
      courseName: course,
      assignmentName: name,
      deadline: _deadline,
      difficulty: _selectedDifficulty ?? 'Medium',
      isIndividual: _isIndividual,
    );
    if (_editingIndex != null && entry.id != null && entry.id!.isNotEmpty) {
      final updated = await PlannerApi.updateDeadline(
        id: entry.id!,
        title: name,
        course: course,
        dueDate: _deadline,
        type: 'assignment',
        difficulty: _selectedDifficulty ?? 'Medium',
        isIndividual: _isIndividual,
      );
      if (updated != null) {
        final idx = deadlineStore.items.indexWhere((i) => i.id == entry.id);
        if (idx >= 0) {
          deadlineStore.updateAt(idx, DeadlineItem(
            id: updated.id,
            title: name,
            courseName: course,
            dueDate: _deadline,
            difficulty: _selectedDifficulty ?? 'Medium',
            isIndividual: _isIndividual,
            type: 'assignment',
          ));
        }
        await PlannerApi.generatePlan(availableHours: 20);
        AppNav.onPlanRegenerated?.call();
      }
      if (!mounted) return;
      setState(() {
        _assignments[_editingIndex!] = entry;
        _editingIndex = null;
        _courseNameController.clear();
        _assignmentNameController.clear();
        _deadline = null;
        _selectedDifficulty = _difficulties[1];
        _isIndividual = true;
      });
      return;
    }
    if (_editingIndex == null) {
      final created = await PlannerApi.createDeadline(
        title: name,
        course: course,
        dueDate: _deadline,
        type: 'assignment',
        difficulty: _selectedDifficulty ?? 'Medium',
        isIndividual: _isIndividual,
      );
      if (created != null) {
        deadlineStore.add(DeadlineItem(
          id: created.id,
          title: name,
          courseName: course,
          dueDate: _deadline,
          difficulty: _selectedDifficulty ?? 'Medium',
          isIndividual: _isIndividual,
        ));
        // Brief delay in setup flow so Firestore has the deadline before generatePlan fetches it
        await Future.delayed(const Duration(milliseconds: 500));
        final plan = await PlannerApi.generatePlan(availableHours: 20);
        AppNav.onPlanRegenerated?.call();
        if (plan == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan saved but generation failed. Try opening Planner tab to retry.'), backgroundColor: Colors.orange),
          );
        }
        if (!mounted) return;
        setState(() {
          _assignments.add(_AssignmentEntry(
            id: created.id,
            courseName: course,
            assignmentName: name,
            deadline: _deadline,
            difficulty: _selectedDifficulty ?? 'Medium',
            isIndividual: _isIndividual,
          ));
          _courseNameController.clear();
          _assignmentNameController.clear();
          _deadline = null;
          _selectedDifficulty = _difficulties[1];
          _isIndividual = true;
        });
        return;
      }
    }
    setState(() {
      if (_editingIndex != null) {
        _assignments[_editingIndex!] = entry;
        _editingIndex = null;
      } else {
        _assignments.add(entry);
      }
      _courseNameController.clear();
      _assignmentNameController.clear();
      _deadline = null;
      _selectedDifficulty = _difficulties[1];
      _isIndividual = true;
    });
  }

  void _editAssignment(int index) {
    final a = _assignments[index];
    _courseNameController.text = a.courseName;
    _assignmentNameController.text = a.assignmentName;
    _deadline = a.deadline;
    _selectedDifficulty = a.difficulty;
    _isIndividual = a.isIndividual;
    setState(() => _editingIndex = index);
  }

  Future<void> _deleteAssignment(int index) async {
    final entry = _assignments[index];
    if (entry.id != null && entry.id!.isNotEmpty) {
      await PlannerApi.deleteDeadline(entry.id!);
    }
    if (!mounted) return;
    setState(() {
      _assignments.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _courseNameController.clear();
        _assignmentNameController.clear();
        _deadline = null;
        _selectedDifficulty = _difficulties[1];
        _isIndividual = true;
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(foregroundColor: _darkPurple),
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            color: _darkPurple,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth > 600 ? 24.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'Assignments & Tasks',
                    style: TextStyle(
                      color: _titlePurple,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _SectionCard(
                  title: 'Add New Assignment/Task',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: 'Course Name',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _courseNameController,
                              decoration: _inputDecoration(hint: 'Enter Course'),
                            ),
                            const SizedBox(height: 6),
                            _hint('e.g. CS101'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Assignment/Task Name',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _assignmentNameController,
                              decoration: _inputDecoration(hint: 'Enter Assignment/Task'),
                            ),
                            const SizedBox(height: 6),
                            _hint('e.g. Network Documentation'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _LabeledField(
                              label: 'Deadline',
                              child: InkWell(
                                onTap: () => _pickDate(context),
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    hintText: 'dd/mm/yyyy',
                                    hintStyle: const TextStyle(color: _hintGray),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    suffixIcon: const Icon(Icons.calendar_today, color: _hintGray, size: 20),
                                  ),
                                  child: Text(
                                    _formatDate(_deadline),
                                    style: TextStyle(
                                      color: _deadline == null ? _hintGray : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LabeledField(
                              label: 'Difficulty',
                              child: DropdownButtonFormField<String>(
                                value: _selectedDifficulty,
                                decoration: _inputDecoration(),
                                borderRadius: BorderRadius.circular(8),
                                items: _difficulties
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedDifficulty = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Type',
                        child: Row(
                          children: [
                            Expanded(
                              child: _TypeChip(
                                label: 'Individual',
                                selected: _isIndividual,
                                onTap: () => setState(() => _isIndividual = true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TypeChip(
                                label: 'Group',
                                selected: !_isIndividual,
                                onTap: () => setState(() => _isIndividual = false),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _addAssignment,
                          icon: Icon(_editingIndex != null ? Icons.check : Icons.add, size: 20),
                          label: Text(_editingIndex != null ? 'Update Assignment/Task' : 'Add Assignment/Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lightPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Added Assignments/Tasks (${_assignments.length})',
                  child: _assignments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No assignments/tasks added yet. Add your upcoming deadlines.',
                              style: TextStyle(fontSize: 14, color: _hintGray),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _assignments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _AddedAssignmentCard(
                            entry: _assignments[i],
                            formatDateLong: _formatDateLong,
                            onEdit: () => _editAssignment(i),
                            onDelete: () => _deleteAssignment(i),
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _goNext(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _skipButtonColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Skip to Focus Profile'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _assignments.isNotEmpty ? () => _goNext(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _nextButtonColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goNext(BuildContext context) {
    // Use pushNamed so Back from Focus returns here with form state preserved.
    Navigator.of(context).pushNamed(AppRoutes.focusAndEnergyProfile);
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintGray),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _hint(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: _hintGray));
  }
}

class _AssignmentEntry {
  final String? id; // backend deadline id; set when created or loaded
  final String courseName;
  final String assignmentName;
  final DateTime? deadline;
  final String difficulty;
  final bool isIndividual;

  _AssignmentEntry({
    this.id,
    required this.courseName,
    required this.assignmentName,
    this.deadline,
    required this.difficulty,
    required this.isIndividual,
  });
}

class _AddedAssignmentCard extends StatelessWidget {
  const _AddedAssignmentCard({
    required this.entry,
    required this.formatDateLong,
    required this.onEdit,
    required this.onDelete,
  });

  final _AssignmentEntry entry;
  final String Function(DateTime?) formatDateLong;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _darkPurple = Color(0xFF4A5568);
  static const _detailGrey = Color(0xFF6A7282);
  // Difficulty label colors
  static const _easyBg = Color(0xFFDCFCE7);   // light green
  static const _easyText = Color(0xFF166534); // green
  static const _mediumBg = Color(0xFFFEF9C3); // light yellow
  static const _mediumText = Color(0xFF854D0E); // yellow-brown
  static const _hardBg = Color(0xFFFEE2E2);  // light red
  static const _hardText = Color(0xFF991B1B); // red

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
                  entry.assignmentName,
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
                      formatDateLong(entry.deadline),
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
      default: // Medium
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  static const _darkPurple = Color(0xFF4A5568);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _darkPurple,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  static const _darkPurple = Color(0xFF4A5568);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: _darkPurple.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _lightPurple = Color(0xFFB8C4E3);
  static const _pageBackground = Color(0xFFF5F0E8);
  static const _darkPurple = Color(0xFF4A5568);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _lightPurple : _pageBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _darkPurple,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
