import 'package:flutter/material.dart';

/// Icon keys stored on habits by the API, with their display icon and default tint.
const habitIconChoices = <String, (IconData, Color)>{
  'sunrise': (Icons.wb_sunny, Color(0xFFF9A825)),
  'prayer': (Icons.self_improvement, Color(0xFF8D6E63)),
  'fitness': (Icons.fitness_center, Color(0xFF455A64)),
  'shake': (Icons.local_drink, Color(0xFFE91E63)),
  'book': (Icons.menu_book, Color(0xFF1565C0)),
  'water': (Icons.water_drop, Color(0xFF1E88E5)),
  'leaf': (Icons.eco, Color(0xFF43A047)),
  'lunch': (Icons.restaurant, Color(0xFFEF6C00)),
  'dance': (Icons.sports_gymnastics, Color(0xFF7B1FA2)),
  'bed': (Icons.bed, Color(0xFF3949AB)),
  'walk': (Icons.directions_walk, Color(0xFF00897B)),
  'check': (Icons.check_circle_outline, Color(0xFF2E7D32)),
};

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF2E7D32)}) {
  if (hex == null || !hex.startsWith('#')) return fallback;
  final value = hex.substring(1);
  final argb = value.length == 6 ? 'FF$value' : value;
  final parsed = int.tryParse(argb, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class HabitIcon extends StatelessWidget {
  const HabitIcon({super.key, required this.icon, this.color, this.size = 22});

  final String icon;
  final String? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final choice = habitIconChoices[icon] ?? habitIconChoices['check']!;
    final tint = parseHexColor(color, fallback: choice.$2);
    return Icon(choice.$1, color: tint, size: size);
  }
}
