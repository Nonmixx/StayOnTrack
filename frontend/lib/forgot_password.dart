import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'check_email.dart'; // Make sure this file exists in your project
import 'login.dart'; // Make sure this file exists in your project

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;

    // The top cream section takes ~42% of the screen height
    final topSectionHeight = screenHeight * 0.42;

    // The lavender card fills the remaining height (screen - top section)
    final cardHeight = screenHeight - topSectionHeight + safePadding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Stack(
        children: [
          // ── Top cream section (fills ~42% of screen) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Image.asset(
                    'assets/images/latest_logo.png',
                    height: 100,
                    width: 100,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom lavender card (fills remaining screen) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6CFE6).withOpacity(0.80),
              ),
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Reset Password" heading — Allan Bold 36
                  Text(
                    'Reset Password',
                    style: GoogleFonts.allan(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2D4E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtitle — Arimo size 14 color #708090 opacity 98%
                  Text(
                    "Enter the email associated with your account and we'll send an email with instruction to reset your password.",
                    style: GoogleFonts.arimo(
                      fontSize: 14,
                      color: const Color(0xFF708090).withOpacity(0.98),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email input field
                  _buildEmailField(),

                  const SizedBox(height: 80),

                  // Send + Cancel buttons side by side
                  Row(
                    children: [
                      // Send button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CheckEmailPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C9EC3),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Send',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Cancel button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C9EC3),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Floating image overlapping both sections ──
          Positioned(
            top: topSectionHeight - 230,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/forgot_password_image.png',
                height: 250,
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/email.png',
            height: 22,
            width: 22,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle:
                TextStyle(color: Colors.grey.shade500, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              style:
              const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}