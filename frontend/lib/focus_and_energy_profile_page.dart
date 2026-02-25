import 'package:flutter/material.dart';
import 'routes.dart';
import 'api/planner_api.dart';
import 'api/focus_api.dart';

/// Focus & Energy Profile screen. Shown after Assignment and Project (or Skip to Focus Profile).
class FocusAndEnergyProfilePage extends StatefulWidget {
  const FocusAndEnergyProfilePage({super.key});

  @override
  State<FocusAndEnergyProfilePage> createState() => _FocusAndEnergyProfilePageState();
}

class _FocusAndEnergyProfilePageState extends State<FocusAndEnergyProfilePage> {
  final Set<int> _peakFocusIndices = {};   // multi-select (no overlap with low energy)
  final Set<int> _lowEnergyIndices = {};   // multi-select (no overlap with peak)
  int? _studyDurationIndex; // 0 = 20 min, ... 6 = Other
  final _otherDurationController = TextEditingController();

  static const _titlePurple = Color(0xFF7E93CC);
  static const _darkPurple = Color(0xFF4A5568);
  static const _pageBackground = Color(0xFFF5F0E8);
  static const _hintGray = Color(0xFF9CA3AF);
  static const _cardLavender = Color(0xFF9C9EC3); // section header bg
  static const _cardLavenderLight = Color(0xFFB8C4E3);
  static const _selectedChip = Color(0xFF7E93CC);
  static const _buttonPurple = Color(0xFF9C9EC3);

  static const _peakFocusOptions = [
    'Early Morning (6am - 9am)',
    'Morning (9am - 12pm)',
    'Afternoon (12pm - 5pm)',
    'Evening (5pm - 9pm)',
    'Late Night (9pm - 1am)',
    'Overnight (1am - 6am)',
  ];

  static const _studyDurationOptions = [
    '20 minutes',
    '30 minutes',
    '45 minutes',
    '1 hour',
    '1.5 hours',
    '2 hours+',
    'Other',
  ];

  bool get _isOtherDuration => _studyDurationIndex == _studyDurationOptions.length - 1;
  bool get _hasOtherDurationValue => _otherDurationController.text.trim().isNotEmpty;
  bool get _canGeneratePlan => !_isOtherDuration || _hasOtherDurationValue;

  @override
  void initState() {
    super.initState();
    _peakFocusIndices.add(3);   // Default: Evening
    _lowEnergyIndices.add(2);   // Default: Afternoon
    _studyDurationIndex = 2;    // Default: 45 minutes
    _otherDurationController.addListener(() => setState(() {}));
    _loadExistingProfile();
  }

  /// Restore saved focus profile when returning to this page (e.g. from Semester Setup flow).
  Future<void> _loadExistingProfile() async {
    final profiles = await FocusApi.getFocusProfiles();
    if (!mounted || profiles.isEmpty) return;
    final p = profiles.first;
    setState(() {
      _peakFocusIndices.clear();
      for (final label in p.peakFocusTimes ?? <String>[]) {
        final i = _peakFocusOptions.indexOf(label);
        if (i >= 0) _peakFocusIndices.add(i);
      }
      if (_peakFocusIndices.isEmpty) _peakFocusIndices.add(3);

      _lowEnergyIndices.clear();
      for (final label in p.lowEnergyTimes ?? <String>[]) {
        final i = _peakFocusOptions.indexOf(label);
        if (i >= 0) _lowEnergyIndices.add(i);
      }
      if (_lowEnergyIndices.isEmpty) _lowEnergyIndices.add(2);

      final duration = p.typicalStudyDuration?.trim() ?? '';
      final optionIndex = _studyDurationOptions.indexOf(duration);
      if (optionIndex >= 0) {
        _studyDurationIndex = optionIndex;
        if (optionIndex == _studyDurationOptions.length - 1) _otherDurationController.clear();
      } else if (duration.isNotEmpty) {
        _studyDurationIndex = _studyDurationOptions.length - 1;
        _otherDurationController.text = duration;
      }
    });
  }

  @override
  void dispose() {
    _otherDurationController.dispose();
    super.dispose();
  }

  void _togglePeakFocus(int i) {
    setState(() {
      if (_peakFocusIndices.contains(i)) {
        _peakFocusIndices.remove(i);
      } else {
        _peakFocusIndices.add(i);
        _lowEnergyIndices.remove(i); // cannot be both peak and low
      }
    });
  }

  void _toggleLowEnergy(int i) {
    setState(() {
      if (_lowEnergyIndices.contains(i)) {
        _lowEnergyIndices.remove(i);
      } else {
        _lowEnergyIndices.add(i);
        _peakFocusIndices.remove(i); // cannot be both
      }
    });
  }

  String get _typicalStudyDuration {
    if (_isOtherDuration) return _otherDurationController.text.trim();
    if (_studyDurationIndex != null && _studyDurationIndex! < _studyDurationOptions.length) {
      return _studyDurationOptions[_studyDurationIndex!];
    }
    return '1 hour';
  }

  List<String> get _peakFocusLabels =>
      _peakFocusIndices.map((i) => _peakFocusOptions[i]).toList();

  List<String> get _lowEnergyLabels =>
      _lowEnergyIndices.map((i) => _peakFocusOptions[i]).toList();

  Future<void> _generatePlan(BuildContext context) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF7E93CC)),
                SizedBox(height: 16),
                Text('Generating your study plan...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final profiles = await FocusApi.getFocusProfiles();
      bool focusSaved = false;
      if (profiles.isEmpty) {
        final created = await FocusApi.createFocusProfile(
          peakFocusTimes: _peakFocusLabels,
          lowEnergyTimes: _lowEnergyLabels,
          typicalStudyDuration: _typicalStudyDuration,
        );
        focusSaved = created != null;
      } else {
        final updated = await FocusApi.updateFocusProfile(profiles.first.id,
          peakFocusTimes: _peakFocusLabels,
          lowEnergyTimes: _lowEnergyLabels,
          typicalStudyDuration: _typicalStudyDuration,
        );
        focusSaved = updated != null;
      }
      if (!focusSaved && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save focus profile to database. Check that the backend is running and Firestore is configured.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      // Small delay to ensure Firestore has persisted the focus profile before plan generation reads it
      await Future.delayed(const Duration(milliseconds: 500));
      final plan = await PlannerApi.generatePlan(availableHours: 20);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        if (plan != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate plan. Ensure backend is running (mvn spring-boot:run in backend folder).'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate plan. Ensure backend is running.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Focus & Energy Profile',
                        style: TextStyle(
                          color: _titlePurple,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help our AI understand your study habits to optimize your schedule.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _darkPurple.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _LavenderSectionCard(
                  title: 'Peak Focus Times',
                  question: 'When do you feel most productive?',
                  backgroundColor: const Color(0xFFAFBCDD),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_peakFocusOptions.length, (i) {
                      final selected = _peakFocusIndices.contains(i);
                      return _TimeChip(
                        label: _peakFocusOptions[i],
                        selected: selected,
                        selectedColor: const Color(0xFF7C7FA8),
                        onTap: () => _togglePeakFocus(i),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                _LavenderSectionCard(
                  title: 'Low Energy Times',
                  question: 'When do you usually feel tired or distracted? (Cannot select the same time as Peak Focus.)',
                  backgroundColor: const Color(0xFFE3E8F6),
                  titleAndQuestionColor: _darkPurple,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_peakFocusOptions.length, (i) {
                      final selected = _lowEnergyIndices.contains(i);
                      return _TimeChip(
                        label: _peakFocusOptions[i],
                        selected: selected,
                        selectedColor: const Color(0xFF8B92B8),
                        onTap: () => _toggleLowEnergy(i),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                _DottedBorderSectionCard(
                  title: 'Typical Study Duration',
                  question: 'How long can you study before needing a break?',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_studyDurationOptions.length, (i) {
                          final selected = _studyDurationIndex == i;
                          return _TimeChip(
                            label: _studyDurationOptions[i],
                            selected: selected,
                            onTap: () => setState(() => _studyDurationIndex = i),
                          );
                        }),
                      ),
                      if (_studyDurationIndex == _studyDurationOptions.length - 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _otherDurationController,
                            decoration: InputDecoration(
                              hintText: 'e.g. 90 minutes',
                              hintStyle: const TextStyle(color: _hintGray, fontSize: 14),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            style: const TextStyle(
                              color: _darkPurple,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canGeneratePlan ? () => _generatePlan(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Generate My Plan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LavenderSectionCard extends StatelessWidget {
  const _LavenderSectionCard({
    required this.title,
    required this.question,
    required this.child,
    required this.backgroundColor,
    this.titleAndQuestionColor,
  });

  final String title;
  final String question;
  final Widget child;
  final Color backgroundColor;
  final Color? titleAndQuestionColor;

  @override
  Widget build(BuildContext context) {
    final textColor = titleAndQuestionColor ?? Colors.white;
    final questionColor = titleAndQuestionColor ?? Colors.white.withValues(alpha: 0.9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
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
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            question,
            style: TextStyle(
              color: questionColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DottedBorderSectionCard extends StatelessWidget {
  const _DottedBorderSectionCard({
    required this.title,
    required this.question,
    required this.child,
  });

  final String title;
  final String question;
  final Widget child;

  static const _darkPurple = Color(0xFF4A5568);
  static const _dottedBorder = Color(0xFF7E93CC);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _dottedBorder,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            question,
            style: TextStyle(
              color: _darkPurple.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  static const _selectedBgDefault = Color(0xFF7E93CC);
  static const _darkPurple = Color(0xFF4A5568);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? (selectedColor ?? _selectedBgDefault) : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
