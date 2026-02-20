import 'package:flutter/material.dart';

/// Empty state card matching StayOnTrack design.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1)),
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
        ],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFAFBCDD).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFAFBCDD)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF101828),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Arimo',
              fontSize: 14,
              height: 1.43,
              color: Color(0xFF6A7282),
              fontWeight: FontWeight.w400,
            ),
          ),
          if (buttonLabel != null && onButtonTap != null) ...[
            const SizedBox(height: 20),
            InkWell(
              onTap: onButtonTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFAFBCDD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  buttonLabel!,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 14,
                    height: 1.43,
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
