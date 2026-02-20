import 'package:flutter/material.dart';

/// Page 6.1 - Group Overview
/// Displays a list of all group assignments with their status
class GroupPage extends StatelessWidget {
  const GroupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Group Assignments List Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Group Assignments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Group Assignment Card 1
                _buildGroupCard(
                  context: context,
                  courseCode: 'MKT305',
                  groupName: 'MarketMinds',
                  assignmentTitle: 'Marketing Strategy Deck',
                  deadline: 'Due 15 Nov',
                  status: 'On track',
                  statusColor: Colors.green,
                  memberInitials: ['A', 'S', 'M'],
                ),
                const SizedBox(height: 16),

                // Group Assignment Card 2
                _buildGroupCard(
                  context: context,
                  courseCode: 'CS450',
                  groupName: 'UI Dreamers',
                  assignmentTitle: 'Mobile App Prototype',
                  deadline: 'Due 30 Oct',
                  status: 'At risk',
                  statusColor: Colors.red,
                  memberInitials: ['J', 'E'],
                ),
              ],
            ),
          ),

          // New Group Assignment Button Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Page 6.2 - Assignment Setup
                  Navigator.pushNamed(context, '/group-assignment-setup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9FA8DA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ New Group Assignment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(context, selectedIndex: 2),
    );
  }

  /// Builds individual group assignment card
  Widget _buildGroupCard({
    required BuildContext context,
    required String courseCode,
    required String groupName,
    required String assignmentTitle,
    required String deadline,
    required String status,
    required Color statusColor,
    required List<String> memberInitials,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to Page 6.4 - Task Distribution (or detail page)
        Navigator.pushNamed(context, '/task-distribution');
      },
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Code and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  courseCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Group Name
            Text(
              groupName,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),

            // Assignment Title
            Text(
              assignmentTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Deadline and Member Avatars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Deadline
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      deadline,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Member Initial Avatars
                Row(
                  children: [
                    ...memberInitials.map(
                      (initial) => Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar Widget
  Widget _buildBottomNavBar(
    BuildContext context, {
    required int selectedIndex,
  }) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF5C6BC0),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Group',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        // Handle navigation
      },
    );
  }
}
