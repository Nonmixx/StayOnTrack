import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_1.dart';
import 'welcome_3.dart';

class Welcome2 extends StatelessWidget {
  const Welcome2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // ── Top Logo ──────────────────────────────────────
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/latest_logo.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Main Illustration ─────────────────────────────
              Expanded(
                child: Image.asset(
                  'assets/images/Welcome_page_image_2.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 16),

              // ── Title (Arimo Bold Italic, size 20) ────────────
              Text(
                'We will be your most reliable\nassignment partner',
                textAlign: TextAlign.center,
                style: GoogleFonts.arimo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF2D2D4E),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // ── Page Indicator Dots ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: false),
                  const SizedBox(width: 8),
                  _Dot(active: true),
                  const SizedBox(width: 8),
                  _Dot(active: false),
                ],
              ),

              const SizedBox(height: 24),

              // ── Bottom Navigation ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous → WelcomePage1
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const WelcomePage1(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B6B8A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                    child: Text(
                      'Previous',
                      style: GoogleFonts.arimo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B6B8A),
                      ),
                    ),
                  ),

                  // Next → Welcome3
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const Welcome3(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C9EC3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: GoogleFonts.arimo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dot indicator widget ───────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF9C9EC3) : Colors.transparent,
        shape: BoxShape.circle,
        border: active
            ? null
            : Border.all(color: const Color(0xFF9C9EC3), width: 1.5),
      ),
    );
  }
}