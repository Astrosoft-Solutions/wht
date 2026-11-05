import '../habits/data/habit.dart';

class PlannedReminder {
  const PlannedReminder({required this.habit, required this.at, required this.start, required this.index});

  final Habit habit;
  final DateTime at;

  /// The habit's start time on the day this reminder belongs to.
  final DateTime start;

  /// 0 for the "starts in 15 minutes" reminder, then 1, 2, ... for each repeat.
  final int index;

  bool get isBeforeStart => at.isBefore(start);
}

/// Works out when habit reminders fire: [leadTime] before each habit starts, then every
/// [interval] until the habit's end time. Habits already completed today get no reminders today.
class ReminderPlanner {
  const ReminderPlanner({
    this.leadTime = const Duration(minutes: 15),
    this.interval = const Duration(minutes: 15),
    this.windowWithoutEnd = const Duration(hours: 1),
    this.maxPerHabitPerDay = 16,
  });

  final Duration leadTime;
  final Duration interval;

  /// How long to keep reminding when a habit has no end time.
  final Duration windowWithoutEnd;
  final int maxPerHabitPerDay;

  List<PlannedReminder> plan({
    required List<Habit> habits,
    required Set<int> completedToday,
    required DateTime now,
    required int days,
    required int maxCount,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final result = <PlannedReminder>[];

    for (var d = 0; d < days; d++) {
      final day = DateTime(today.year, today.month, today.day + d);
      for (final habit in habits) {
        if (!habit.isActive || !_scheduledOn(habit, day)) continue;
        if (d == 0 && completedToday.contains(habit.id)) continue;

        final start = _at(day, habit.startTime);
        var end = habit.endTime == null ? start.add(windowWithoutEnd) : _at(day, habit.endTime!);
        if (!end.isAfter(start)) end = start.add(windowWithoutEnd);

        var at = start.subtract(leadTime);
        for (var i = 0; i < maxPerHabitPerDay && !at.isAfter(end); i++) {
          if (at.isAfter(now)) result.add(PlannedReminder(habit: habit, at: at, start: start, index: i));
          at = at.add(interval);
        }
      }
    }

    result.sort((a, b) => a.at.compareTo(b.at));
    return result.length > maxCount ? result.sublist(0, maxCount) : result;
  }

  bool _scheduledOn(Habit habit, DateTime day) {
    final days = habit.daysOfWeek;
    return days == null || days.isEmpty || days.contains(day.weekday);
  }

  DateTime _at(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
