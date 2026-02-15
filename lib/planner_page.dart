import 'package:flutter/material.dart';
import 'monthly_planner_page.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Planner',
          style: TextStyle(
            fontFamily: 'Arimo',
            fontSize: 20,
            height: 1.2,
            color: Color(0xFF101828),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              MonthCard(
                month: 'January',
                abbreviation: 'Jan',
                color: const Color(0xFFAFBCDD),
                itemCount: '2 assignments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyPlannerPage(month: 'January'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              MonthCard(
                month: 'February',
                abbreviation: 'Feb',
                color: const Color(0xFFAFBCDD),
                itemCount: '2 exams',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyPlannerPage(month: 'February'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              MonthCard(
                month: 'March',
                abbreviation: 'Mar',
                color: const Color(0xFFAFBCDD),
                itemCount: '2 exams',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyPlannerPage(month: 'March'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthCard extends StatelessWidget {
  final String month;
  final String abbreviation;
  final Color color;
  final String itemCount;
  final VoidCallback onTap;

  const MonthCard({
    Key? key,
    required this.month,
    required this.abbreviation,
    required this.color,
    required this.itemCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 17.6, right: 17.6, top: 17.6, bottom: 1.6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          border: Border.all(color: const Color(0xFF7BF1A8), width: 1.6),
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Month badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      abbreviation,
                      style: const TextStyle(
                        fontFamily: 'Arimo',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    month,
                    style: const TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF101828),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF99A1AF),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C9EC3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  itemCount,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 14,
                    height: 1.43,
                    color: Color(0xFF4A5565),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}