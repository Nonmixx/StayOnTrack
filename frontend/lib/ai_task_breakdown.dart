import 'package:flutter/material.dart';

/// Page 6.3 - AI Task Breakdown
/// Displays AI-generated tasks from the assignment brief
class TaskBreakdownPage extends StatelessWidget {
  const TaskBreakdownPage({Key? key}) : super(key: key);

  // Dummy task data
  final List<Map<String, dynamic>> _tasks = const [
    {
      'id': 1,
      'title': 'Competitor Analysis',
      'description':
          'Research similar mobile applications, compare features, strengths, and weaknesses to identify improvement opportunities.',
      'effort': 'Medium',
      'effortColor': Color(0xFFFF9800),
      'dependencies': null,
    },
    {
      'id': 2,
      'title': 'Slide Deck Template',
      'description':
          'Design a clean and professional slide template aligned with the project theme and branding.',
      'effort': 'Low',
      'effortColor': Color(0xFF4CAF50),
      'dependencies': null,
    },
    {
      'id': 3,
      'title': 'Executive Summary',
      'description':
          'Write a concise overview explaining the app concept, objectives, and expected impact.',
      'effort': 'High',
      'effortColor': Color(0xFFF44336),
      'dependencies': null,
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
        title: const Text('AI Task Breakdown'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Task List Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: These tasks were derived from the assignment brief.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Task Cards
                ..._tasks.map((task) => _buildTaskCard(task)),
              ],
            ),
          ),

          // Action Buttons Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Distribute Tasks Button (Primary)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Page 6.4 - Task Distribution
                      Navigator.pushNamed(context, '/task-distribution');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9FA8DA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Distribute Tasks',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Regenerate Tasks Button (Secondary)
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      // Regenerate tasks logic
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
                      'Regenerate Tasks',
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

  /// Build individual task card
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Number and Title Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Number Circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${task['id']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Text(
                    task['title'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              task['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Effort Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (task['effortColor'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task['effort'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: task['effortColor'],
                ),
              ),
            ),

            // Dependencies (if any)
            if (task['dependencies'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Depends on: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task['dependencies'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
