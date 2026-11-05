import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/reminder_providers.dart';
import '../../reports/providers/report_providers.dart';
import '../data/habit.dart';
import '../data/habit_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<Dashboard>(
  (ref) => ref.watch(habitRepositoryProvider).dashboard(),
);

final habitScheduleProvider = FutureProvider.autoDispose.family<HabitSchedule, HabitRange>(
  (ref, range) => ref.watch(habitRepositoryProvider).schedule(range),
);

final habitActionsProvider = Provider<HabitActions>((ref) => HabitActions(ref));

/// Increments each time the user finishes every habit for the day; the shell plays confetti.
final celebrationProvider = NotifierProvider<Celebration, int>(Celebration.new);

class Celebration extends Notifier<int> {
  @override
  int build() => 0;

  void fire() => state++;
}

/// Habit mutations; each one refreshes every screen that shows habit progress.
class HabitActions {
  HabitActions(this._ref);

  final Ref _ref;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  Future<void> toggle(int habitId) async {
    _celebrateIfDone(await _repo.toggle(habitId));
    _refresh();
  }

  Future<void> completeAll() async {
    _celebrateIfDone(await _repo.completeAll());
    _refresh();
  }

  void _celebrateIfDone(DayStats stats) {
    if (stats.total > 0 && stats.completed >= stats.total) {
      _ref.read(celebrationProvider.notifier).fire();
    }
  }

  Future<void> save(HabitInput input, {int? id}) async {
    if (id == null) {
      await _repo.create(input);
    } else {
      await _repo.update(id, input);
    }
    _refresh();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _refresh();
  }

  /// For changes made outside these methods, e.g. adding habits from templates.
  void refreshAll() => _refresh();

  void _refresh() {
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(habitScheduleProvider);
    _ref.invalidate(monthlyReportProvider);
    // Completing a habit stops its remaining reminders for today; edits move its reminder times.
    unawaited(_ref.read(reminderSyncProvider).sync());
  }
}
