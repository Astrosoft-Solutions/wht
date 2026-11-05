import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Full-screen loading indicator: the leaf mark breathing inside a rotating gradient arc.
class BrandLoader extends StatefulWidget {
  const BrandLoader({super.key, this.size = 64, this.label});

  final double size;
  final String? label;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = 0.88 + 0.12 * math.sin(_controller.value * 2 * math.pi).abs();
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: CustomPaint(size: Size.square(size), painter: _ArcPainter(track: context.palette.mint)),
                  ),
                  Transform.scale(scale: pulse, child: child),
                ],
              );
            },
            child: AppLogoMark(size: size * 0.42),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: Gaps.m),
          Text(widget.label!, style: TextStyle(color: context.palette.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.track});

  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 1.2,
      false,
      Paint()
        ..shader = const SweepGradient(colors: [Color(0x0043A047), AppColors.accent, AppColors.brand], stops: [0, 0.5, 0.6])
            .createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => oldDelegate.track != track;
}

/// Three bouncing dots for busy buttons.
class DotsLoader extends StatefulWidget {
  const DotsLoader({super.key, this.color = Colors.white, this.size = 7});

  final Color color;
  final double size;

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.35),
              child: Transform.translate(
                offset: Offset(0, -widget.size * 0.6 * math.max(0, math.sin((_controller.value - i * 0.18) * 2 * math.pi))),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A filled button that swaps its label for [DotsLoader] while [busy].
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.onPressed, required this.label, this.busy = false, this.icon});

  final VoidCallback? onPressed;
  final String label;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: busy
            ? const SizedBox(key: ValueKey('busy'), height: 22, child: Center(child: DotsLoader()))
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}
