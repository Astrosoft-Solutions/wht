import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/onboarding_provider.dart';

final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(ThemeModeSetting.new);

class ThemeModeSetting extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = mode;
  }
}
