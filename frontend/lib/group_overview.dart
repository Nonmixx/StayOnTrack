import 'package:flutter/material.dart';

/// Page 6.1 - Group Overview
class GroupPage extends StatelessWidget {
  const GroupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text(
          'Group',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF101828),
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Group Assignments',
                      style: TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── CHANGED: pass assignmentId + all card data ──
                    _buildGroupCard(
                      context: context,
                      assignmentId: 'assignment-001', // real id from backend
                      courseCode: 'MKT305',
                      groupName: 'MarketMinds',
                      assignmentTitle: 'Marketing Strategy Deck',
                      deadline: 'Due 15 Nov',
                      status: 'On track',
                      statusColor: const Color(0xFF008236),
                      statusBgColor: const Color(0xFFDBFCE7),
                      memberInitials: ['A', 'S', 'M'],
                    ),
                    const SizedBox(height: 16),

                    _buildGroupCard(
                      context: context,
                      assignmentId: 'assignment-002', // real id from backend
                      courseCode: 'CS450',
                      groupName: 'UI Dreamers',
                      assignmentTitle: 'Mobile App Prototype',
                      deadline: 'Due 30 Oct',
                      status: 'At risk',
                      statusColor: const Color(0xFFE70030),
                      statusBgColor: const Color(0xFFFEE2E2),
                      memberInitials: ['J', 'E'],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/group-assignment-setup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFBCDD),
                    foregroundColor: const Color(0xFFFFFFFF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '+ New Group Assignment',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required String assignmentId, // ── CHANGED: added assignmentId param ──
    required String courseCode,
    required String groupName,
    required String assignmentTitle,
    required String deadline,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required List<String> memberInitials,
  }) {
    return GestureDetector(
      // ── CHANGED: pass assignmentId as route argument ──
      onTap: () {
        Navigator.pushNamed(
          context,
          '/task-distribution',
          arguments: {'assignmentId': assignmentId},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E6EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  courseCode,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    color: Color(0xFF9CB3CC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                groupName,
                style: const TextStyle(
                  fontFamily: 'Arimo',
                  fontSize: 13,
                  color: Color(0xFF4A5565),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),

            Text(
              assignmentTitle,
              style: const TextStyle(
                fontFamily: 'Arimo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF99A1AF),
                ),
                const SizedBox(width: 5),
                Text(
                  deadline,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    color: Color(0xFF99A1AF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 34,
                  width: memberInitials.length * 22.0 + 12,
                  child: Stack(
                    children: [
                      for (int i = 0; i < memberInitials.length; i++)
                        Positioned(
                          left: i * 22.0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFFFFF),
                                width: 2,
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
                            child: Center(
                              child: Text(
                                memberInitials[i],
                                style: const TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFAFBCDD),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFBCDD),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAFBCDD).withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
