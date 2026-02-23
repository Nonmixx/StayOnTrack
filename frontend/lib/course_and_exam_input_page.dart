import 'package:flutter/material.dart';
import 'routes.dart';
import 'api/planner_api.dart';
import 'data/deadline_store.dart';

/// Course and Exam Input screen (Exam Schedule). Shown after Semester Setup.
class CourseAndExamInputPage extends StatefulWidget {
  const CourseAndExamInputPage({super.key});

  @override
  State<CourseAndExamInputPage> createState() => _CourseAndExamInputPageState();
}

class _CourseAndExamInputPageState extends State<CourseAndExamInputPage> {
  final _courseNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _otherTypeController = TextEditingController();
  String? _selectedExamType;
  DateTime? _examDate;
  int _weightValue = 0;
  final List<_ExamEntry> _exams = [];
  int? _editingIndex;

  // Match home_page.dart Actions: Next = Weekly Check-in, Skip = Add Deadline
  static const _nextButtonColor = Color(0xFF9C9EC3); // Weekly Check-in
  static const _skipButtonColor = Color(0xFFAFBCDD); // Add Deadline
  static const _darkPurple = Color(0xFF4A5568);
  static const _lightPurple = Color(0xFFB8C4E3); // Add Exam button
  static const _titlePurple = Color(0xFF7E93CC);
  static const _pageBackground = Color(0xFFF5F0E8);
  static const _hintGray = Color(0xFF9CA3AF);

  static const _examTypes = ['Midterm', 'Final', 'Quiz', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedExamType ??= _examTypes.first;
    _weightController.text = '0';
    _weightController.addListener(_syncWeightFromController);
  }

  void _syncWeightFromController() {
    final v = int.tryParse(_weightController.text);
    if (v != null && v != _weightValue && v >= 0 && v <= 100) {
      setState(() => _weightValue = v);
    }
  }

  @override
  void dispose() {
    _weightController.removeListener(_syncWeightFromController);
    _courseNameController.dispose();
    _weightController.dispose();
    _otherTypeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$m/$d/$y';
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _formatDateLong(DateTime? date) {
    if (date == null) return '';
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get _effectiveExamType {
    if (_selectedExamType == 'Other') {
      final t = _otherTypeController.text.trim();
      return t.isEmpty ? 'Other' : t;
    }
    return _selectedExamType ?? _examTypes.first;
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _addExam() async {
    final course = _courseNameController.text.trim();
    if (course.isEmpty) return;
    final entry = _ExamEntry(
      courseName: course,
      examType: _effectiveExamType,
      date: _examDate,
      weight: _weightValue,
    );
    if (_editingIndex == null) {
      final created = await PlannerApi.createDeadline(
        title: '$course - ${entry.examType}',
        course: course,
        dueDate: entry.date,
        type: 'exam',
      );
      if (created != null) {
        deadlineStore.add(DeadlineItem(
          id: created.id,
          title: '$course - ${entry.examType}',
          courseName: course,
          dueDate: entry.date,
          difficulty: entry.weight != null ? '${entry.weight}%' : '—',
          isIndividual: true,
        ));
        await PlannerApi.generatePlan(availableHours: 20);
      }
    }
    setState(() {
      if (_editingIndex != null) {
        _exams[_editingIndex!] = entry;
        _editingIndex = null;
      } else {
        _exams.add(entry);
      }
      _clearForm();
    });
  }

  void _clearForm() {
    _courseNameController.clear();
    _weightController.clear();
    _weightValue = 0;
    _weightController.text = '0';
    _otherTypeController.clear();
    _examDate = null;
    _selectedExamType = _examTypes.first;
  }

  void _editExam(int index) {
    final e = _exams[index];
    _courseNameController.text = e.courseName;
    _weightController.text = '${e.weight ?? 0}';
    _weightValue = e.weight ?? 0;
    _otherTypeController.text = _examTypes.contains(e.examType) ? '' : e.examType;
    _selectedExamType = _examTypes.contains(e.examType) ? e.examType : 'Other';
    _examDate = e.date;
    setState(() => _editingIndex = index);
  }

  void _deleteExam(int index) {
    setState(() {
      _exams.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _clearForm();
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
          style: IconButton.styleFrom(
            foregroundColor: _darkPurple,
          ),
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
                // Title
                Center(
                  child: Text(
                    'Exam Schedule',
                    style: TextStyle(
                      color: _titlePurple,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Add New Exam card
                _SectionCard(
                  title: 'Add New Exam',
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
                            hintText('e.g. CS101'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Exam Type',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedExamType,
                              decoration: _inputDecoration(),
                              borderRadius: BorderRadius.circular(8),
                              items: _examTypes
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedExamType = v),
                            ),
                            if (_selectedExamType == 'Other') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _otherTypeController,
                                decoration: _inputDecoration(hint: 'Enter exam type'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Date',
                        child: InkWell(
                          onTap: () => _pickDate(context),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              hintText: 'mm/dd/yyyy',
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
                              _formatDate(_examDate),
                              style: TextStyle(
                                color: _examDate == null ? _hintGray : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Weight (%)',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                onChanged: (s) {
                                  final v = int.tryParse(s);
                                  if (v != null && v >= 0 && v <= 100) {
                                    setState(() => _weightValue = v);
                                  }
                                },
                                decoration: _inputDecoration(hint: 'Enter Exam Weight'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_weightValue < 100) {
                                      setState(() {
                                        _weightValue++;
                                        _weightController.text = '$_weightValue';
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_up),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: _darkPurple,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (_weightValue > 0) {
                                      setState(() {
                                        _weightValue--;
                                        _weightController.text = '$_weightValue';
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: _darkPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _addExam,
                            icon: Icon(_editingIndex != null ? Icons.check : Icons.add, size: 20),
                            label: Text(_editingIndex != null ? 'Update Exam' : 'Add Exam'),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scheduled Exams card
                _SectionCard(
                  title: 'Scheduled Exams (${_exams.length})',
                  child: _exams.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No exams added yet. Add your first exam to get started.',
                              style: TextStyle(
                                fontSize: 14,
                                color: _hintGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _exams.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _ScheduledExamCard(
                            entry: _exams[i],
                            formatDateLong: _formatDateLong,
                            onEdit: () => _editExam(i),
                            onDelete: () => _deleteExam(i),
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                // Footer: Skip always allowed; Next only when at least one exam is added
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _goToHome(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _skipButtonColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Skip to Assignments'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _exams.isNotEmpty ? () => _goToHome(context) : null,
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

  void _goToHome(BuildContext context) {
    // TODO: Persist exams if needed
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
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

  Widget hintText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: _hintGray),
    );
  }
}

class _ExamEntry {
  final String courseName;
  final String examType;
  final DateTime? date;
  final int? weight;

  _ExamEntry({
    required this.courseName,
    required this.examType,
    this.date,
    this.weight,
  });
}

class _ScheduledExamCard extends StatelessWidget {
  const _ScheduledExamCard({
    required this.entry,
    required this.formatDateLong,
    required this.onEdit,
    required this.onDelete,
  });

  final _ExamEntry entry;
  final String Function(DateTime?) formatDateLong;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _darkPurple = Color(0xFF4A5568);
  static const _detailPurple = Color(0xFF7E93CC); // Light purplish-blue for type & weight

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
          // Left: selection circle
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
                // Course code (e.g. CS1234)
                Text(
                  entry.courseName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _darkPurple,
                  ),
                ),
                const SizedBox(height: 6),
                // Bullet: Exam Type (light purplish-blue)
                _bulletLine(entry.examType, _detailPurple),
                _bulletLine(
                  entry.weight != null ? '${entry.weight}% Weight' : '—',
                  _detailPurple,
                ),
                _bulletLine(formatDateLong(entry.date), _darkPurple),
              ],
            ),
          ),
          // Top right: edit and delete icons
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

  Widget _bulletLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: TextStyle(fontSize: 14, color: color),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  static const _cardBackground = Color(0xFFFFFFFF);
  static const _darkPurple = Color(0xFF4A5568);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
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
