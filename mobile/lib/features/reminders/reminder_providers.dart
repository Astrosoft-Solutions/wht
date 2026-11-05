import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers/auth_controller.dart';
import '../auth/providers/onboarding_provider.dart';
import '../content/data/content_repository.dart';
import '../habits/data/habit.dart';
import '../habits/data/habit_repository.dart';
import 'reminder_service.dart';

final remindersEnabledProvider = NotifierProvider<RemindersEnabled, bool>(RemindersEnabled.new);

class RemindersEnabled extends Notifier<bool> {
  static const _key = 'habit_reminders_enabled';

  @override
  bool build() => ReminderService.isSupported && (ref.watch(sharedPreferencesProvider).getBool(_key) ?? true);

  /// False until the user flips the switch; until then the superadmin's default applies.
  bool get userHasChosen => ref.read(sharedPreferencesProvider).containsKey(_userChoiceKey);

  static const _userChoiceKey = 'habit_reminders_user_choice';

  Future<void> applyDefault(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    state = enabled;
  }

  /// Returns false when the user declines the notification permission.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await ReminderService.instance.requestPermission(exactAlarms: true)) {
      enabled = false;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, enabled);
    await prefs.setBool(_userChoiceKey, true);
    state = enabled;
    if (enabled) {
      await ref.read(reminderSyncProvider).sync();
    } else {
      await ReminderService.instance.clear();
    }
    return enabled;
  }
}

final reminderSyncProvider = Provider<ReminderSync>((ref) => ReminderSync(ref));

/// Rebuilds the reminder schedule from the server's habits and today's completions.
class ReminderSync {
  ReminderSync(this._ref);

  static const _permissionAskedKey = 'habit_reminders_permission_asked';

  final Ref _ref;
  Future<void>? _running;
  bool _again = false;

  /// Overlapping calls (e.g. several quick toggles) collapse into one extra run.
  Future<void> sync() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _run().whenComplete(() => _running = null);
  }

  Future<void> _run() async {
    do {
      _again = false;
      await _syncOnce();
    } while (_again);
  }

  Future<void> _syncOnce() async {
    if (!ReminderService.isSupported) return;
    final service = ReminderService.instance;
    final signedIn = _ref.read(authControllerProvider).value != null;
    if (!signedIn || !_ref.read(remindersEnabledProvider)) {
      await service.clear();
      return;
    }

    ReminderSettings settings;
    try {
      settings = await _ref.read(contentRepositoryProvider).reminderSettings();
    } catch (_) {
      settings = const ReminderSettings();
    }

    final enabled = _ref.read(remindersEnabledProvider.notifier);
    if (!enabled.userHasChosen && !settings.defaultOn) {
      await enabled.applyDefault(false);
      await service.clear();
      return;
    }

    final prefs = _ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(_permissionAskedKey) ?? false)) {
      await prefs.setBool(_permissionAskedKey, true);
      if (!await service.requestPermission()) {
        await enabled.setEnabled(false);
        return;
      }
    }

    try {
      final repo = _ref.read(habitRepositoryProvider);
      final results = await Future.wait([repo.all(), repo.schedule(HabitRange.today)]);
      final habits = results[0] as List<Habit>;
      final today = results[1] as HabitSchedule;
      await service.reschedule(
        habits: habits,
        completedToday: {for (final h in today.habits) if (h.isCompleted) h.id},
        leadMinutes: settings.leadMinutes,
        intervalMinutes: settings.intervalMinutes,
      );
    } catch (_) {
      // Offline or server error: keep the previously scheduled reminders.
    }
  }
}
