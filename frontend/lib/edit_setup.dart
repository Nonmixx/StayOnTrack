import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// Page 6.5 - Edit Setup
class EditSetupPage extends StatefulWidget {
  const EditSetupPage({Key? key}) : super(key: key);

  @override
  State<EditSetupPage> createState() => _EditSetupPageState();
}

class _EditSetupPageState extends State<EditSetupPage> {
  final TextEditingController _groupNameController = TextEditingController(
    text: 'MarketMinds',
  );
  final TextEditingController _courseNameController = TextEditingController(
    text: 'MKT305',
  );
  final TextEditingController _assignmentTitleController =
      TextEditingController(text: 'Marketing Strategy Deck');
  final TextEditingController _briefController = TextEditingController(
    text: 'Create a comprehensive marketing strategy...',
  );

  DateTime? _selectedDeadline = DateTime(2023, 11, 15, 23, 59);
  String? _uploadedFileName;
  bool _isAddMemberHovered = false;
  String _assignmentId = '';

  List<Map<String, dynamic>> _members = [
    {
      'name': TextEditingController(text: 'Alex'),
      'strengths': <String>['Coding', 'Research', 'Presentation'],
    },
    {
      'name': TextEditingController(text: 'Sarah'),
      'strengths': <String>['Writing', 'Design'],
    },
    {
      'name': TextEditingController(text: 'Mike'),
      'strengths': <String>['Research'],
    },
  ];

  final List<String> _availableStrengths = [
    'Coding',
    'Research',
    'Writing',
    'Design',
    'Presentation',
    'Testing',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final id = args?['assignmentId'] as String? ?? '';
    if (id.isNotEmpty && _assignmentId != id) _assignmentId = id;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() {
        _uploadedFileName = result.files.first.name;
      });
    }
  }

  BoxDecoration get _inputBoxDecoration => BoxDecoration(
    color: const Color(0xFFFFFFFF),
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
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Arimo',
      color: Color(0xFF99A1AF),
      fontSize: 14,
    ),
    filled: true,
    fillColor: const Color(0xFFFFFFFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFAFBCDD), width: 1.5),
    ),
    contentPadding: const EdgeInsets.all(12),
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
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
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
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
          'Edit Setup',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF101828),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroupMembersSection(),
          const SizedBox(height: 16),
          _buildAssignmentDetailsSection(),
          const SizedBox(height: 16),
          _buildAssignmentBriefSection(),
          const SizedBox(height: 24),
          _buildGenerateButton(),
          const SizedBox(height: 32),
        ],
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

  Widget _buildGroupMembersSection() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group Members',
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE7E6EB), thickness: 1, height: 1),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE7E6EB), width: 1),
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
              children: [
                const Text(
                  'GROUP NAME',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    color: Color(0xFF909EC3),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: _inputBoxDecoration,
                    child: TextField(
                      controller: _groupNameController,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14,
                        color: Color(0xFF2D2D3A),
                      ),
                      decoration: _fieldDecoration('Enter group name'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ..._members.asMap().entries.map(
            (entry) => _buildMemberCard(entry.key, entry.value),
          ),

          const SizedBox(height: 4),

          // ── CHANGED: dashed border stays, color changes on hover ──
          MouseRegion(
            onEnter: (_) => setState(() => _isAddMemberHovered = true),
            onExit: (_) => setState(() => _isAddMemberHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _members.add({
                    'name': TextEditingController(),
                    'strengths': <String>[],
                  });
                });
              },
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: _isAddMemberHovered
                      ? const Color(0xFFAFBCDD)
                      : const Color(0xFF99A1AF),
                  borderRadius: 10,
                  dashWidth: 6,
                  dashSpace: 4,
                  strokeWidth: _isAddMemberHovered ? 1.8 : 1.5,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isAddMemberHovered
                        ? const Color(0xFFEFF3FB)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: _isAddMemberHovered
                              ? const Color(0xFFAFBCDD)
                              : const Color(0xFF99A1AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add member',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isAddMemberHovered
                                ? const Color(0xFFAFBCDD)
                                : const Color(0xFF99A1AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(int index, Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E6EB), width: 1),
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
              Text(
                'MEMBER ${index + 1}',
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 12,
                  color: Color(0xFF909EC3),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _members.removeAt(index)),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF909EC3),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: _inputBoxDecoration,
            child: TextField(
              controller: member['name'],
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 14,
                color: Color(0xFF2D2D3A),
              ),
              decoration: _fieldDecoration('Enter name'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Strengths',
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 13,
              color: Color(0xFF6A7282),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStrengths.map((strength) {
              final bool isSelected = (member['strengths'] as List<String>)
                  .contains(strength);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      (member['strengths'] as List<String>).remove(strength);
                    } else {
                      (member['strengths'] as List<String>).add(strength);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFAFBCDD)
                        : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFAFBCDD)
                          : const Color(0xFFE7E6EB),
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
                  child: Text(
                    strength,
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF6A7282),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentDetailsSection() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Details',
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE7E6EB), thickness: 1, height: 1),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Course Name',
            controller: _courseNameController,
            hint: 'e.g. CS101',
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Assignment Title',
            controller: _assignmentTitleController,
            hint: 'e.g. Final Group Project',
          ),
          const SizedBox(height: 16),
          const Text(
            'Deadline',
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF364153),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDeadline ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate != null) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    _selectedDeadline ?? DateTime.now(),
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: false),
                    child: child!,
                  ),
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedDeadline = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7E6EB), width: 1),
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
                children: [
                  Expanded(
                    child: Text(
                      _selectedDeadline != null
                          ? _formatDeadline(_selectedDeadline!)
                          : 'dd/mm/yyyy  --:-- --',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 14,
                        color: _selectedDeadline != null
                            ? const Color(0xFF2D2D3A)
                            : const Color(0xFF909EC3),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF909EC3),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime dt) {
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    final String year = dt.year.toString();
    final int hour12 = dt.hour == 0
        ? 12
        : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$day/$month/$year  ${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }

  Widget _buildAssignmentBriefSection() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Questions / Brief',
            style: TextStyle(
              fontFamily: 'Arimo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE7E6EB), thickness: 1, height: 1),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7E6EB), width: 1),
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
            child: TextField(
              controller: _briefController,
              maxLines: 6,
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 14,
                color: Color(0xFF2D2D3A),
              ),
              decoration: InputDecoration(
                hintText: 'Paste assignment questions or brief here...',
                hintStyle: const TextStyle(
                  fontFamily: 'Arimo',
                  color: Color(0xFF99A1AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFAFBCDD),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE7E6EB), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    color: Color(0xFF99A1AF),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE7E6EB), thickness: 1)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickFile,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFAFBCDD),
                borderRadius: 8,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _uploadedFileName != null
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      color: _uploadedFileName != null
                          ? const Color(0xFF008236)
                          : const Color(0xFF909EC3),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadedFileName ?? 'Upload PDF / DOC',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        color: _uploadedFileName != null
                            ? const Color(0xFF008236)
                            : const Color(0xFF909EC3),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBEDBFF), width: 1),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF5D7AA3),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI will analyze this to identify required tasks.',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 13,
                      color: Color(0xFF5D7AA3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
          backgroundColor: const Color(0xFF9C9EC3),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Generate Tasks with AI',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Arimo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF364153),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: _inputBoxDecoration,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              color: Color(0xFF2D2D3A),
            ),
            decoration: _fieldDecoration(hint),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _courseNameController.dispose();
    _assignmentTitleController.dispose();
    _briefController.dispose();
    for (var member in _members) {
      (member['name'] as TextEditingController).dispose();
    }
    super.dispose();
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    this.borderRadius = 8,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final Path path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : dashSpace;
        if (draw)
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.strokeWidth != strokeWidth;
}
