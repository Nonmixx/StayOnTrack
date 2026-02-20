import 'package:flutter/material.dart';

/// Page 6.4 - AI Task Distribution
/// Shows how AI has distributed tasks among team members
class TaskDistributionPage extends StatelessWidget {
  const TaskDistributionPage({Key? key}) : super(key: key);

  // Dummy data for task distribution
  final List<Map<String, dynamic>> _memberDistributions = const [
    {
      'name': 'Alex',
      'initial': 'A',
      'strengths': 'RESEARCH, PRESENTATION',
      'taskCount': 1,
      'tasks': [
        {
          'title': 'Competitor Analysis',
          'description':
              'Research similar mobile applications, compare features, strengths, and weaknesses to identify improvement opportunities.',
          'effort': 'Medium',
          'effortColor': Color(0xFFFF9800),
          'reason':
              'Assigned to Alex due to strong research and presentation skills.',
        },
      ],
    },
    {
      'name': 'Sarah',
      'initial': 'S',
      'strengths': 'DESIGN, WRITING',
      'taskCount': 2,
      'tasks': [
        {
          'title': 'Slide Deck Template',
          'description':
              'Design a clean and professional slide template aligned with the project theme and branding.',
          'effort': 'Low',
          'effortColor': Color(0xFF4CAF50),
          'reason': 'Assigned to Sarah due to design expertise.',
          'dependencies': 'Executive Summary',
        },
        {
          'title': 'Executive Summary',
          'description':
              'Write a concise overview explaining the app concept, objectives, and expected impact.',
          'effort': 'High',
          'effortColor': Color(0xFFF44336),
          'reason': 'Assigned to Sarah due to design expertise.',
        },
      ],
    },
    {
      'name': 'Mike',
      'initial': 'M',
      'strengths': 'RESEARCH',
      'taskCount': 0,
      'tasks': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI Task Distribution'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9FA8DA), Color(0xFF7986CB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'On track',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Course Code
                Text(
                  'MKT305',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Assignment Title
                const Text(
                  'Marketing Strategy Deck',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Group Name and Metadata Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'GROUP NAME:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'MarketMinds',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Due Wed, 15 Nov',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.assignment_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '3 Tasks Total',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Task Distribution Section Header with Edit Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Task Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate back to edit setup
                    Navigator.pushNamed(context, '/edit-setup');
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Setup'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9FA8DA),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: const Color(0xFFE8EAF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Member Task Lists
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _memberDistributions.length,
              itemBuilder: (context, index) {
                return _buildMemberSection(_memberDistributions[index]);
              },
            ),
          ),

          // Action Buttons Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Confirm Button (Primary)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to Group Overview or show success
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9FA8DA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Regenerate Distribution Button (Secondary)
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      // Regenerate distribution logic
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF9FA8DA),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Regenerate Distribution',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9FA8DA),
                      ),
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

  /// Build member section with their assigned tasks
  Widget _buildMemberSection(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Member Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EAF6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member['initial'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Member Name and Strengths
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member['strengths'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Task Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${member['taskCount']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks List
          if ((member['tasks'] as List).isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No tasks assigned',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...(member['tasks'] as List).map((task) => _buildTaskCard(task)),
        ],
      ),
    );
  }

  /// Build individual task card within member section
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title and Effort Badge Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (task['effortColor'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task['effort'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: task['effortColor'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Task Description
          Text(
            task['description'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),

          // AI Reason (Explanation)
          if (task['reason'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFF7B1FA2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task['reason'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B1FA2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Dependencies
          if (task['dependencies'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Depends on: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  task['dependencies'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
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
