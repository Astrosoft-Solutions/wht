import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Leaf emblem with a figure in the middle, matching the WellnessHabitTrack brand mark.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 64, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final leafColor = onDark || context.isDark ? const Color(0xFF9CCC65) : AppColors.brandLight;
    return SizedBox(
      width: size * 1.4,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.6,
              child: Icon(Icons.eco, size: size * 0.75, color: leafColor),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.flip(
              flipX: true,
              child: Transform.rotate(
                angle: -0.6,
                child: Icon(Icons.eco, size: size * 0.75, color: leafColor),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: size * 0.05,
            child: Icon(Icons.spa, size: size * 0.55, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 22, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'WellnessHabitTrack',
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color ?? context.palette.primary,
        letterSpacing: -0.3,
      ),
    );
  }
}
