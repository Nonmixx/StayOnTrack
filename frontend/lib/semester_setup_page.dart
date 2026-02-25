import 'package:flutter/material.dart';
import 'routes.dart';
import 'api/semester_api.dart';
import 'utils/calendar_utils.dart';

class SemesterSetupPage extends StatefulWidget {
  const SemesterSetupPage({super.key});

  @override
  State<SemesterSetupPage> createState() => _SemesterSetupPageState();
}

class _SemesterSetupPageState extends State<SemesterSetupPage> {
  final _semesterNameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFullTime = true;
  final Set<int> _restDays = {}; // 1 = Monday, 7 = Sunday
  /// After first save, backend returns documentId; use PUT on subsequent Next to avoid duplicates.
  String? _savedSemesterId;

  static const _lightPurple = Color(0xFFB8C4E3);
  static const _darkPurple = Color(0xFF4A5568);
  static const _titlePurple = Color(0xFF7E93CC); // Same as Exam Schedule title
  static const _pageBackground = Color(0xFFF5F0E8);
  static const _cardBackground = Color(0xFFFFFFFF);
  static const _hintGray = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _loadExistingSemester();
  }

  @override
  void dispose() {
    _semesterNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSemester() async {
    final list = await SemesterApi.getSemesters();
    if (!mounted || list.isEmpty) return;
    final s = list.first;
    setState(() {
      _savedSemesterId = s.id;
      if (s.semesterName != null && s.semesterName!.isNotEmpty) {
        _semesterNameController.text = s.semesterName!;
      }
      if (s.startDate != null) _startDate = _parseIsoDate(s.startDate!);
      if (s.endDate != null) _endDate = _parseIsoDate(s.endDate!);
      if (s.studyMode != null) _isFullTime = s.studyMode == 'full-time';
      if (s.restDays != null) {
        _restDays.clear();
        for (final d in s.restDays!) {
          final i = int.tryParse(d);
          if (i != null && i >= 1 && i <= 7) _restDays.add(i);
        }
      }
    });
  }

  static DateTime? _parseIsoDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return CalendarUtils.formatDisplay(date);
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initial = isStartDate ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final first = isStartDate ? DateTime(now.year - 2, 1, 1) : (_startDate ?? now);
    final last = DateTime(now.year + 2, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _onNext(BuildContext context) async {
    if (_startDate == null || _endDate == null) return;
    final name = _semesterNameController.text.trim();
    final studyMode = _isFullTime ? 'full-time' : 'part-time';
    final restDays = _restDays.isEmpty ? null : _restDays.map((d) => d.toString()).toList();
    Semester? result;
    if (_savedSemesterId != null && _savedSemesterId!.isNotEmpty) {
      result = await SemesterApi.updateSemester(
        semesterId: _savedSemesterId!,
        semesterName: name.isEmpty ? 'Semester' : name,
        startDate: _startDate!,
        endDate: _endDate!,
        studyMode: studyMode,
        restDays: restDays,
      );
    } else {
      result = await SemesterApi.createSemester(
        semesterName: name.isEmpty ? 'Semester' : name,
        startDate: _startDate!,
        endDate: _endDate!,
        studyMode: studyMode,
        restDays: restDays,
      );
      if (result != null) _savedSemesterId = result.id;
    }
    if (result != null && context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.courseAndExamInput);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save semester. Is the backend running?')),
      );
    }
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
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(foregroundColor: _darkPurple),
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth > 600 ? 24.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title (matches Exam Schedule layout)
                  Center(
                    child: Text(
                      'Semester Setup',
                      style: TextStyle(
                        color: _titlePurple,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Define your academic timeline so we can plan your workload.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _darkPurple.withValues(alpha: 0.8),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Semester Name card
                  _SectionCard(
                    title: 'Semester Name',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _semesterNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter Semester',
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
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'e.g. Semester 1 2025/2026',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hintGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Semester Duration card
                  _SectionCard(
                    title: 'Semester Duration',
                    child: Column(
                      children: [
                        _DateField(
                          label: 'Start Date',
                          value: _formatDate(_startDate),
                          onTap: () => _pickDate(context, true),
                        ),
                        const SizedBox(height: 16),
                        _DateField(
                          label: 'End Date',
                          value: _formatDate(_endDate),
                          onTap: () => _pickDate(context, false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Study Mode card
                  _SectionCard(
                    title: 'Study Mode',
                    child: Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            label: 'Full-time',
                            selected: _isFullTime,
                            onTap: () => setState(() => _isFullTime = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChoiceChip(
                            label: 'Part-time',
                            selected: !_isFullTime,
                            onTap: () => setState(() => _isFullTime = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rest Days card
                  _SectionCard(
                    title: 'Rest Days',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select days you prefer to rest',
                          style: TextStyle(
                            fontSize: 14,
                            color: _darkPurple.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(7, (i) {
                            final day = i + 1;
                            final selected = _restDays.contains(day);
                            return _DayChip(
                              label: _weekdays[i],
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _restDays.remove(day);
                                  } else {
                                    _restDays.add(day);
                                  }
                                });
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startDate == null || _endDate == null
                          ? null
                          : () => _onNext(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lightPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  static const _hintGray = Color(0xFF9CA3AF);

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
        InkWell(
          onTap: onTap,
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
              value.isEmpty ? '' : value,
              style: TextStyle(
                color: value.isEmpty ? _hintGray : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _darkPurple = Color(0xFF4A5568);
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _darkPurple,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
