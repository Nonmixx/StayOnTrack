import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  /// The page to navigate to after the splash finishes.
  final Widget nextPage;

  /// How long the splash is shown before navigating (default 2.5 s).
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.nextPage,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Spinning arc animation
  late final AnimationController _spinController;
  // Fade + scale for the logo / text
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Spinner – continuous rotation
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Logo entrance – fade in + slight scale up
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();

    // Auto-navigate after [duration]
    Future.delayed(widget.duration, _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => widget.nextPage,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E2F0),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Owl logo ──────────────────────────────
                Image.asset(
                  'assets/images/latest_logo.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                // ── Spinning arc indicator ─────────────────
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (_, __) => CustomPaint(
                    size: const Size(36, 36),
                    painter: _ArcSpinnerPainter(
                      progress: _spinController.value,
                      color: const Color(0xFF7B61FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Arc spinner (matches the purple arc in the
//  original screenshot)
// ─────────────────────────────────────────────
class _ArcSpinnerPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  const _ArcSpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;

    // Draw a 270° arc that rotates
    canvas.drawArc(
      rect.deflate(paint.strokeWidth / 2),
      _deg2rad(progress * 360 - 90),
      _deg2rad(270),
      false,
      paint,
    );
  }

  double _deg2rad(double deg) => deg * pi / 180;

  @override
  bool shouldRepaint(_ArcSpinnerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
//  SplashRoute – convenience PageRoute wrapper
// ─────────────────────────────────────────────
///
/// Usage:
///   Navigator.of(context).push(SplashRoute(builder: (_) => MyPage()));
///
class SplashRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  final Duration splashDuration;

  SplashRoute({
    required this.builder,
    this.splashDuration = const Duration(milliseconds: 2500),
  }) : super(
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, __) => SplashScreen(
      nextPage: builder(context),
      duration: splashDuration,
    ),
  );
}
