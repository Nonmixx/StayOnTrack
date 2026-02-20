import 'package:flutter/material.dart';

/// Page 6.5 / Edit Setup
/// Allows editing of existing group assignment setup
/// This is essentially the same as Page 6.2 but with pre-filled data
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

  // Pre-filled member data
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Setup'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECTION A: Group Members
          _buildGroupMembersSection(),
          const SizedBox(height: 24),

          // SECTION B: Assignment Details
          _buildAssignmentDetailsSection(),
          const SizedBox(height: 24),

          // SECTION C: Assignment Questions/Brief
          _buildAssignmentBriefSection(),
          const SizedBox(height: 24),

          // SECTION D: Generate Tasks Button
          _buildGenerateButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// SECTION A: Group Members
  Widget _buildGroupMembersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group Members',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Group Name Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GROUP NAME',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member List
          ..._members.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> member = entry.value;
            return _buildMemberCard(index, member);
          }),

          // Add Member Button
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _members.add({
                  'name': TextEditingController(),
                  'strengths': <String>[],
                });
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Add member',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Member Card
  Widget _buildMemberCard(int index, Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Header with Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MEMBER ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                onPressed: () {
                  setState(() {
                    _members.removeAt(index);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name Input
          TextField(
            controller: member['name'],
            decoration: InputDecoration(
              hintText: 'Enter name',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          // Strengths Label
          Text(
            'Strengths',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Strength Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStrengths.map((strength) {
              bool isSelected = (member['strengths'] as List<String>).contains(
                strength,
              );
              return FilterChip(
                label: Text(strength),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      (member['strengths'] as List<String>).add(strength);
                    } else {
                      (member['strengths'] as List<String>).remove(strength);
                    }
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF9FA8DA),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF9FA8DA)
                      : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// SECTION B: Assignment Details
  Widget _buildAssignmentDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Course Name
          _buildTextField(
            label: 'Course Name',
            controller: _courseNameController,
            hint: 'e.g. CS101',
          ),
          const SizedBox(height: 16),

          // Assignment Title
          _buildTextField(
            label: 'Assignment Title',
            controller: _assignmentTitleController,
            hint: 'e.g. Final Group Project',
          ),
          const SizedBox(height: 16),

          // Deadline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deadline',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDeadline != null
                              ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year} ${_selectedDeadline!.hour}:${_selectedDeadline!.minute.toString().padLeft(2, '0')} PM'
                              : 'dd/mm/yyyy --:--',
                          style: TextStyle(
                            color: _selectedDeadline != null
                                ? Colors.black
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SECTION C: Assignment Questions/Brief
  Widget _buildAssignmentBriefSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Questions / Brief',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Text Area
          TextField(
            controller: _briefController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Paste assignment questions or brief here...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // OR Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),

          // Upload Button
          OutlinedButton(
            onPressed: () {
              // Handle file upload
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Column(
              children: [
                Icon(Icons.upload_file, color: Colors.grey.shade600, size: 28),
                const SizedBox(height: 8),
                Text(
                  'Upload PDF / DOC',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Helper Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI will analyze this to identify required tasks.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// SECTION D: Generate Tasks Button
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to Page 6.3 - AI Task Breakdown
          Navigator.pushNamed(context, '/task-breakdown');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9FA8DA),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Generate Tasks with AI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// Helper: Build Text Field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(12),
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
