import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'forgot_password.dart'; // ResetPasswordPage
import 'change_password.dart'; // ChangePasswordPage – create this next

class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "Check Your Email" heading — Allan Bold 36
                  Text(
                    'Check Your Email',
                    style: GoogleFonts.allan(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2D4E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtitle — Arimo size 16
                  Text(
                    'We have sent a password recover instructions to your email.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.arimo(
                      fontSize: 16,
                      color: const Color(0xFF708090).withOpacity(0.98),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Next button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SetNewPasswordPage()),
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
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // "Did not receive the email?" footer — Arimo size 15
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.arimo(
                        fontSize: 15,
                        color: const Color(0xFF708090),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text:
                          'Did not receive the email? Check your spam email or ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ResetPasswordPage()),
                              );
                            },
                            child: Text(
                              'try another email address',
                              style: GoogleFonts.arimo(
                                fontSize: 15,
                                color: const Color(0xFF9C9EC3),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF9C9EC3),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                'assets/images/check_email_page.png',
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
}