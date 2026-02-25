import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; // LoginPage
import 'profile_setting.dart';

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;

    final topSectionHeight = screenHeight * 0.42;
    final cardHeight = screenHeight - topSectionHeight + safePadding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Stack(
        children: [
          // ── Top cream section ──
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

          // ── Bottom lavender card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6CFE6).withOpacity(0.80),
              ),
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "Create New Password" heading — Allan Bold 36
                  Text(
                    'Create New Password',
                    style: GoogleFonts.allan(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2D4E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password field
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Password',
                    iconAsset: 'assets/images/password.png',
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),

                  // Confirm Password field — uses confirm_password.png (same as signup)
                  _buildInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    iconAsset: 'assets/images/confirm_password.png',
                    obscureText: true,
                  ),

                  const SizedBox(height: 40),

                  // Reset Password button
                  SizedBox(
                    width: double.infinity,
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
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // ── Floating image overlapping both sections ──
          Positioned(
            top: topSectionHeight - 200,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/set_pass_image.png',
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
  }) {
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
            iconAsset,
            height: 22,
            width: 22,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Image.asset(
              'assets/images/reminder.png',
              height: 20,
              width: 20,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}