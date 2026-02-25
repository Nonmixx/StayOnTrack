import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_2.dart';
import 'welcome_3.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayOnTrack AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C9EC3),
        ),
        useMaterial3: true,
      ),
      home: const WelcomePage1(),
    );
  }
}

class WelcomePage1 extends StatelessWidget {
  const WelcomePage1({super.key});

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

              const SizedBox(height: 15),

              // ── Main Illustration ─────────────────────────────
              Expanded(
                child: Image.asset(
                  'assets/images/Welcome_page_image.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 16),

              // ── Title (Allan Bold, size 36) ───────────────────
              Text(
                'Welcome To StayOnTrack AI!',
                textAlign: TextAlign.center,
                style: GoogleFonts.allan(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2D4E),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // ── Subtitle (Arimo Bold Italic, size 20) ─────────
              Text(
                'We are greatly to meet you here...',
                textAlign: TextAlign.center,
                style: GoogleFonts.arimo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF6B6B8A),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── Page Indicator Dots ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: true),
                  const SizedBox(width: 8),
                  _Dot(active: false),
                  const SizedBox(width: 8),
                  _Dot(active: false),
                ],
              ),

              const SizedBox(height: 24),

              // ── Bottom Navigation ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip → Welcome3
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const Welcome3(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B6B8A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Next → Welcome2
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Welcome2(),
                        ),
                      );
                    },
                    icon: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    label: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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