import 'package:flutter/material.dart';

/// Rolling green hills with a rising sun, used at the bottom of the splash screen.
class LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sun = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFFFE082), Color(0x00FFE082)])
          .createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.45), radius: w * 0.45));
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.45, sun);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.12, Paint()..color = const Color(0xFFFFD54F));

    void hill(Color color, double startY, List<Offset> controls, double endY) {
      final path = Path()..moveTo(0, h * startY);
      for (var i = 0; i < controls.length; i += 2) {
        path.quadraticBezierTo(controls[i].dx * w, controls[i].dy * h, controls[i + 1].dx * w, controls[i + 1].dy * h);
      }
      path
        ..lineTo(w, h * endY)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    hill(const Color(0xFF66BB6A), 0.55, const [Offset(0.25, 0.35), Offset(0.5, 0.55), Offset(0.75, 0.72), Offset(1, 0.5)], 0.5);
    hill(const Color(0xFF43A047), 0.7, const [Offset(0.3, 0.5), Offset(0.6, 0.68), Offset(0.85, 0.8), Offset(1, 0.65)], 0.65);
    hill(const Color(0xFF2E7D32), 0.82, const [Offset(0.4, 0.65), Offset(0.7, 0.85), Offset(0.9, 0.95), Offset(1, 0.8)], 0.8);
    hill(const Color(0xFF1B5E20), 0.95, const [Offset(0.5, 0.82), Offset(1, 0.92)], 0.92);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
