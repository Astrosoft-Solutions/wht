import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/widgets/offline_banner.dart';
import 'features/reminders/reminder_service.dart';

class WellnessApp extends ConsumerWidget {
  const WellnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ReminderService.instance.onOpenHabits = () => router.go(Routes.habits);

    return MaterialApp.router(
      title: 'WellnessHabitTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: const Duration(milliseconds: 350),
      routerConfig: router,
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox()),
    );
  }
}
