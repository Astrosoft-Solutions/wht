import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the instance loaded before the app starts.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(OnboardingSeen.new);

class OnboardingSeen extends Notifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}

/// Keeps the splash screen visible for a moment on cold start.
final splashDelayProvider = FutureProvider<void>((ref) => Future.delayed(const Duration(milliseconds: 1600)));
