import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary: isDark ? const Color(0xFF66BB6A) : AppColors.brand,
      onPrimary: isDark ? const Color(0xFF00210A) : Colors.white,
      secondary: AppColors.accent,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: AppColors.danger,
    );

    final body = GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme)
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary);
    TextStyle? heading(TextStyle? s) => GoogleFonts.poppins(textStyle: s, fontWeight: FontWeight.w700, color: p.textPrimary);
    final textTheme = body.copyWith(
      displaySmall: heading(body.displaySmall),
      headlineLarge: heading(body.headlineLarge),
      headlineMedium: heading(body.headlineMedium),
      headlineSmall: heading(body.headlineSmall),
      titleLarge: heading(body.titleLarge),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    final radius = BorderRadius.circular(14);
    final transitions = PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
              ? const CupertinoPageTransitionsBuilder()
              : const FadeForwardsPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      pageTransitionsTheme: transitions,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.border)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 1.5)),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.8)),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.primary)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(color: p.surface, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface, surfaceTintColor: Colors.transparent),
      dialogTheme: DialogThemeData(backgroundColor: p.surface, surfaceTintColor: Colors.transparent),
      drawerTheme: DrawerThemeData(backgroundColor: p.surface, surfaceTintColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(color: p.surface, surfaceTintColor: Colors.transparent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.brandLight : null),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
