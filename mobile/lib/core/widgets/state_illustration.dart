import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Friendly illustration for empty, error and offline states, built from layered shapes and an icon.
class StateIllustration extends StatelessWidget {
  const StateIllustration({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = color ?? p.primary;
    final size = compact ? 96.0 : 132.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gaps.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size * 1.5,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(color: tint.withValues(alpha: 0.08), shape: BoxShape.circle),
                  ),
                  Container(
                    width: size * 0.72,
                    height: size * 0.72,
                    decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), shape: BoxShape.circle),
                  ),
                  Positioned(left: size * 0.12, top: size * 0.14, child: _Dot(size: 10, color: AppColors.gold)),
                  Positioned(right: size * 0.1, top: size * 0.3, child: _Dot(size: 7, color: tint.withValues(alpha: 0.5))),
                  Positioned(right: size * 0.22, bottom: size * 0.08, child: _Dot(size: 12, color: AppColors.accent.withValues(alpha: 0.4))),
                  Container(
                    width: size * 0.46,
                    height: size * 0.46,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(size * 0.14),
                      boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(icon, color: tint, size: size * 0.24),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
            const SizedBox(height: Gaps.l),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: Gaps.s),
              Text(message!, textAlign: TextAlign.center, style: TextStyle(color: p.textSecondary, height: 1.4)),
            ],
            if (action != null) ...[const SizedBox(height: Gaps.l), action!],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
