import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stayontrack/semester_setup_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_session.dart'; // ← replaced authstore.dart
import 'login.dart';
import 'personal_information.dart';
import 'notification.dart';
import 'pets_settings.dart';
import 'semester_setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextStyle _arimo(double size,
      {Color color = Colors.black, FontWeight weight = FontWeight.normal}) =>
      GoogleFonts.arimo(fontSize: size, color: color, fontWeight: weight);

  /// Re-read UserSession every time this page comes back into view
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Read directly from UserSession instead of AuthStore.currentUser
    final displayUsername  = (UserSession.username?.isNotEmpty ?? false)
        ? UserSession.username!
        : '';
    final displayEmail = (UserSession.email?.isNotEmpty ?? false)
        ? UserSession.email!
        : 'XXXXXXXX@gmail.com';
    final profileImagePath = UserSession.profileImagePath;

    final screenHeight     = MediaQuery.of(context).size.height;
    final safePadding      = MediaQuery.of(context).padding;
    final topSectionHeight = screenHeight * 0.42;
    final cardHeight       = screenHeight - topSectionHeight + safePadding.top;

    const cream     = Color(0xFFF5F0EB);
    const lavender  = Color(0xFFE6CFE6);
    const emailGrey = Color(0xFF808080);
    const redBtn    = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: GestureDetector(
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
              Text('Back', style: _arimo(16)),
            ],
          ),
        ),
        leadingWidth: 90,
        title: Text('Settings', style: _arimo(16)),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          // ── Top cream area ────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: topSectionHeight,
            child: const SizedBox(),
          ),

          // ── Lavender card ─────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                color: lavender.withOpacity(0.80),
              ),
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Username (bold) + email below
                  if (displayUsername.isNotEmpty) ...[
                    Text(displayUsername,
                        style: _arimo(17,
                            color: const Color(0xFF2D2D2D),
                            weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                  ],
                  Text(displayEmail, style: _arimo(14, color: emailGrey)),
                  const SizedBox(height: 24),

                  // ── Menu items ────────────────────────────────────────────
                  _MenuItem(
                    icon: 'assets/images/personal_information_icon.png',
                    label: 'Personal Information',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                      _refresh(); // refresh after returning from profile page
                    },
                    labelStyle: _arimo(16),
                  ),
                  _buildDivider(),
                  _MenuItem(
                    icon: 'assets/images/notification_icon.png',
                    label: 'Notification Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationSettingsPage()),
                    ),
                    labelStyle: _arimo(16),
                  ),
                  _buildDivider(),
                  _MenuItem(
                    icon: 'assets/images/academic_icon.png',
                    label: 'Academic Details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SemesterSetupPage()),
                    ),
                    labelStyle: _arimo(16),
                  ),
                  _buildDivider(),
                  _MenuItem(
                    icon: 'assets/images/pets_icon.png',
                    label: 'My Pets',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPetsPage()),
                    ),
                    labelStyle: _arimo(16),
                  ),

                  const Spacer(),

                  // ── Logout ────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await UserSession.clear(); // clears SharedPreferences
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redBtn,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.logout,
                          color: Colors.white, size: 22),
                      label: Text('Logout',
                          style: _arimo(24,
                              color: Colors.white,
                              weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Avatar — synced with UserSession ──────────────────────────────
          Positioned(
            top: topSectionHeight - 300,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white,
                backgroundImage: profileImagePath != null
                    ? FileImage(File(profileImagePath))
                    : null,
                child: profileImagePath == null
                    ? const Icon(Icons.person, size: 56, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    thickness: 0.5,
    indent: 8,
    endIndent: 8,
    color: Colors.black26,
  );
}

// ─── Reusable menu row ────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final TextStyle labelStyle;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Image.asset(icon, width: 32, height: 32, fit: BoxFit.contain),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: labelStyle)),
            Image.asset('assets/images/next_icon.png',
                width: 20, height: 20, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}