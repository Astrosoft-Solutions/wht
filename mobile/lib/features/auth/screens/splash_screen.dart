import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/brand_loader.dart';
import '../widgets/landscape_painter.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.brand, AppColors.brandLight, Color(0xFF388E3C)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              top: null,
              child: SizedBox(height: height * 0.42, child: CustomPaint(painter: LandscapePainter()))
                  .animate()
                  .slideY(begin: 0.25, end: 0, duration: 900.ms, curve: Curves.easeOutCubic)
                  .fadeIn(duration: 700.ms),
            ),
            Positioned(
              right: 48,
              bottom: height * 0.08,
              child: const Icon(Icons.directions_run, color: Color(0xFF0D3B12), size: 44)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(begin: -6, end: 6, duration: 700.ms),
            ),
            SafeArea(
              child: Align(
                alignment: const Alignment(0, -0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogoMark(size: 86, onDark: true)
                        .animate()
                        .scale(begin: const Offset(0.6, 0.6), duration: 700.ms, curve: Curves.easeOutBack)
                        .fadeIn(),
                    const SizedBox(height: 18),
                    Text(
                      'Wellness\nHabitTrack',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ).animate(delay: 250.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Plan  \u2022  Track  \u2022  Stay Healthy',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, letterSpacing: 0.4),
                    ).animate(delay: 450.ms).fadeIn(duration: 500.ms),
                    const SizedBox(height: 36),
                    const DotsLoader(size: 8).animate(delay: 700.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
