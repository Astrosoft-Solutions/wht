import 'package:flutter/material.dart';

/// Brand colours that stay the same in light and dark mode. Neutral colours that change with the
/// theme (background, surfaces, text, borders) live in [AppPalette]; read them with `context.palette`.
class AppColors {
  AppColors._();

  /// Deep green used for filled surfaces: headers, buttons, the FAB.
  static const brand = Color(0xFF1B5E20);
  static const brandLight = Color(0xFF2E7D32);
  static const accent = Color(0xFF43A047);
  static const gold = Color(0xFFF9A825);
  static const danger = Color(0xFFE53935);
  static const info = Color(0xFF1E88E5);
  static const warning = Color(0xFFFB8C00);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
  );
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.mint,
    required this.tileGreen,
    required this.tileBlue,
    required this.tileOrange,
    required this.tileRed,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.shadow,
  });

  /// Green for text and icons; lighter in dark mode so it stays readable.
  final Color primary;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  /// Soft green fill for chips, tabs and icon badges.
  final Color mint;
  final Color tileGreen;
  final Color tileBlue;
  final Color tileOrange;
  final Color tileRed;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color shadow;

  static const light = AppPalette(
    primary: Color(0xFF1B5E20),
    background: Color(0xFFF4F7F4),
    surface: Colors.white,
    surfaceMuted: Color(0xFFF0F4F0),
    border: Color(0xFFE0E6E0),
    textPrimary: Color(0xFF1C2B1E),
    textSecondary: Color(0xFF6B7A6D),
    mint: Color(0xFFE8F5E9),
    tileGreen: Color(0xFFE6F4E7),
    tileBlue: Color(0xFFE3F0FD),
    tileOrange: Color(0xFFFFF1E0),
    tileRed: Color(0xFFFDE7E7),
    shimmerBase: Color(0xFFE6ECE6),
    shimmerHighlight: Color(0xFFF7FAF7),
    shadow: Color(0x14000000),
  );

  static const dark = AppPalette(
    primary: Color(0xFF81C784),
    background: Color(0xFF0F1511),
    surface: Color(0xFF18211B),
    surfaceMuted: Color(0xFF1F2A22),
    border: Color(0xFF2C3A30),
    textPrimary: Color(0xFFE6EEE7),
    textSecondary: Color(0xFF9AAE9D),
    mint: Color(0xFF1F3324),
    tileGreen: Color(0xFF1C3121),
    tileBlue: Color(0xFF17283A),
    tileOrange: Color(0xFF33261A),
    tileRed: Color(0xFF3A1E1E),
    shimmerBase: Color(0xFF223026),
    shimmerHighlight: Color(0xFF2D3D31),
    shadow: Color(0x40000000),
  );

  @override
  AppPalette copyWith({Color? primary, Color? background, Color? surface}) => AppPalette(
        primary: primary ?? this.primary,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceMuted: surfaceMuted,
        border: border,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        mint: mint,
        tileGreen: tileGreen,
        tileBlue: tileBlue,
        tileOrange: tileOrange,
        tileRed: tileRed,
        shimmerBase: shimmerBase,
        shimmerHighlight: shimmerHighlight,
        shadow: shadow,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: l(primary, other.primary),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      mint: l(mint, other.mint),
      tileGreen: l(tileGreen, other.tileGreen),
      tileBlue: l(tileBlue, other.tileBlue),
      tileOrange: l(tileOrange, other.tileOrange),
      tileRed: l(tileRed, other.tileRed),
      shimmerBase: l(shimmerBase, other.shimmerBase),
      shimmerHighlight: l(shimmerHighlight, other.shimmerHighlight),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Spacing scale used across screens.
class Gaps {
  Gaps._();

  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
