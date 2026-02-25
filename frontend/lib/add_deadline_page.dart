import 'package:flutter/material.dart';
import 'app_nav.dart';
import 'routes.dart';
import 'api/planner_api.dart';
import 'data/deadline_store.dart';

/// Add Deadline screen. Opened from Home or Edit Deadlines.
/// [editIndex] and [editId] set when editing an existing deadline.
/// [initialType] when editing: preserve existing 'exam' or 'assignment' so we do not overwrite an exam as assignment.
class AddDeadlinePage extends StatefulWidget {
  const AddDeadlinePage({
    super.key,
    this.editIndex,
    this.editId,
    this.initialTitle,
    this.initialCourse,
    this.initialDueDate,
    this.initialDifficulty,
    this.initialIsIndividual,
    this.initialType,
  });

  final int? editIndex;
  final String? editId;
  final String? initialTitle;
  final String? initialCourse;
  final DateTime? initialDueDate;
  final String? initialDifficulty;
  final bool? initialIsIndividual;
  /// When editing, use this type in updateDeadline so an exam is not overwritten as assignment.
  final String? initialType;

  @override
  State<AddDeadlinePage> createState() => _AddDeadlinePageState();
}

class _AddDeadlinePageState extends State<AddDeadlinePage> {
  final _courseNameController = TextEditingController();
  final _titleController = TextEditingController();
  DateTime? _dueDate;
  bool _isIndividual = true;
  String? _selectedDifficulty;

  static const _darkPurple = Color(0xFF4A5568);
  static const _pageBackground = Color(0xFFFFF8F0);
  static const _hintGray = Color(0xFF9CA3AF);
  static const _buttonPurple = Color(0xFFAFBCDD);

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  bool get _isEditMode => widget.editIndex != null || widget.editId != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDifficulty;
    _selectedDifficulty = (initial != null && _difficulties.contains(initial))
        ? initial
        : _difficulties[1];
    _isIndividual = widget.initialIsIndividual ?? true;
    _dueDate = widget.initialDueDate;
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialCourse != null) _courseNameController.text = widget.initialCourse!;
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final course = _courseNameController.text.trim();
    final title = _titleController.text.trim();
    if (course.isEmpty || title.isEmpty) return;

    if (_isEditMode && widget.editId != null) {
      // Preserve existing type when editing so an exam is not overwritten as assignment.
      final type = (widget.initialType ?? 'assignment').toString().trim().toLowerCase();
      final deadlineType = type == 'exam' ? 'exam' : 'assignment';
      final updated = await PlannerApi.updateDeadline(
        id: widget.editId!,
        title: title,
        course: course,
        dueDate: _dueDate,
        type: deadlineType,
        difficulty: _selectedDifficulty,
        isIndividual: _isIndividual,
      );
      if (updated != null && mounted) {
        final item = DeadlineItem(
          id: updated.id,
          title: title,
          courseName: course,
          dueDate: _dueDate,
          difficulty: _selectedDifficulty ?? 'Medium',
          isIndividual: _isIndividual,
          type: widget.initialType ?? 'assignment',
        );
        if (widget.editIndex != null) {
          deadlineStore.updateAt(widget.editIndex!, item);
        }
        await PlannerApi.generatePlan(availableHours: 20);
        AppNav.onPlanRegenerated?.call();
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        _showErrorSnackBar('Failed to update. Please try again.');
      }
      return;
    }

    if (_isEditMode && widget.editIndex != null) {
      final item = DeadlineItem(
        title: title,
        courseName: course,
        dueDate: _dueDate,
        difficulty: _selectedDifficulty ?? 'Medium',
        isIndividual: _isIndividual,
      );
      deadlineStore.updateAt(widget.editIndex!, item);
      Navigator.of(context).pop();
      return;
    }

    final created = await PlannerApi.createDeadline(
      title: title,
      course: course,
      dueDate: _dueDate,
      type: 'assignment',
      difficulty: _selectedDifficulty,
      isIndividual: _isIndividual,
    );
    if (created != null && mounted) {
      final item = DeadlineItem(
        id: created.id,
        title: title,
        courseName: course,
        dueDate: _dueDate,
        difficulty: _selectedDifficulty ?? 'Medium',
        isIndividual: _isIndividual,
      );
      deadlineStore.add(item);
      final plan = await PlannerApi.generatePlan(availableHours: 20);
      AppNav.onPlanRegenerated?.call();
      if (plan == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan saved but generation failed. Try opening Planner tab to retry.'), backgroundColor: Colors.orange),
        );
      }
      _showSuccessDialog();
    } else if (mounted) {
      _showErrorSnackBar('Failed to save. Is the backend running?');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccessDialog() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final fromHomeAdd = args?['fromHomeAdd'] == true;
    final fromEditDeadlinesPage = args?['fromEditDeadlinesPage'] == true;

    if (fromHomeAdd) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assignment/Task added'),
          content: const Text(
            'A new Assignment/Task has been added successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                if (fromEditDeadlinesPage) {
                  Navigator.of(context).pop(); // leave Add Deadline page
                  Navigator.of(context).pop(); // leave Edit Deadline/Exam page → home
                } else {
                  Navigator.of(context).pop(true); // leave Add Deadline page → home, signal refresh
                }
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(true); // leave Add Deadline page, signal refresh
                if (!fromEditDeadlinesPage) {
                  Navigator.of(context).pushNamed(AppRoutes.editDeadlines);
                }
                // if fromEditDeadlinesPage we're already on Edit Deadline/Exam page
              },
              child: const Text('View/Manage Deadline'),
            ),
          ],
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deadline added'),
          content: const Text(
            'New deadline successfully added. You can view or edit deadlines at the Edit Deadlines page.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog only; stay on Add Deadline page
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // leave Add Deadline page
                Navigator.of(context).pushNamed(AppRoutes.editDeadlines);
              },
              child: const Text('View / Edit Deadlines'),
            ),
          ],
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Deadline' : 'Add Deadline',
          style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    _isEditMode ? 'Edit Deadline' : 'Add New Deadline',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Course Name',
                    child: TextField(
                      controller: _courseNameController,
                      decoration: _inputDecoration('e.g. CS101'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Assignment / Task Title',
                    child: TextField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g. Case Study Submission'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Due Date',
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
                          _formatDate(_dueDate),
                          style: TextStyle(
                            color: _dueDate == null ? _hintGray : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
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
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Difficulty',
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: InputDecoration(
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
                      ),
                      borderRadius: BorderRadius.circular(8),
                      items: _difficulties
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDifficulty = v),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(_isEditMode ? 'Update Deadline' : 'Add Deadline'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        currentIndex: 0,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 24), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined, size: 24), label: 'Planner'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 24), label: 'Group'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 24), label: 'Settings'),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
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
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
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

  static const _selectedBg = Color(0xFFC8CEDF);
  static const _unselectedBg = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _selectedBg : _unselectedBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black87 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

