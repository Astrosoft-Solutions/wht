import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_habit_tracker/features/habits/data/habit.dart';
import 'package:wellness_habit_tracker/features/reminders/reminder_planner.dart';

Habit habit(int id, String start, {String? end, List<int>? days, bool active = true}) => Habit(
      id: id,
      name: 'Habit $id',
      icon: 'water',
      color: '#1E88E5',
      startTime: start,
      endTime: end,
      daysOfWeek: days,
      isActive: active,
    );

String hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void main() {
  const planner = ReminderPlanner();
  // Thursday 5 Nov 2026, 06:00.
  final now = DateTime(2026, 11, 5, 6, 0);

  List<PlannedReminder> planToday(List<Habit> habits, {Set<int> completed = const {}}) =>
      planner.plan(habits: habits, completedToday: completed, now: now, days: 1, maxCount: 500);

  test('reminds 15 minutes before start, then every 15 minutes until the end time', () {
    final times = planToday([habit(1, '08:00', end: '09:00')]).map((r) => hm(r.at)).toList();
    expect(times, ['07:45', '08:00', '08:15', '08:30', '08:45', '09:00']);
  });

  test('first reminder is marked as before start', () {
    final reminders = planToday([habit(1, '08:00', end: '08:30')]);
    expect(reminders.first.isBeforeStart, isTrue);
    expect(reminders[1].isBeforeStart, isFalse);
  });

  test('habit without an end time keeps reminding for one hour', () {
    final times = planToday([habit(1, '10:00')]).map((r) => hm(r.at)).toList();
    expect(times, ['09:45', '10:00', '10:15', '10:30', '10:45', '11:00']);
  });

  test('completed habits get no more reminders today', () {
    expect(planToday([habit(1, '08:00', end: '09:00')], completed: {1}), isEmpty);
  });

  test('times already in the past are skipped', () {
    final times = planToday([habit(1, '05:45', end: '06:30')]).map((r) => hm(r.at)).toList();
    expect(times, ['06:15', '06:30']);
  });

  test('respects weekdays and inactive habits', () {
    final reminders = planToday([
      habit(1, '08:00', end: '08:15', days: [1]), // Monday only, today is Thursday
      habit(2, '08:00', end: '08:15', active: false),
      habit(3, '08:00', end: '08:15', days: [4]),
    ]);
    expect(reminders.map((r) => r.habit.id).toSet(), {3});
  });

  test('tomorrow is planned even when today is completed, and results are capped in time order', () {
    final reminders = planner.plan(
      habits: [habit(1, '08:00', end: '08:30')],
      completedToday: {1},
      now: now,
      days: 2,
      maxCount: 2,
    );
    expect(reminders.length, 2);
    expect(reminders.every((r) => r.at.day == 6), isTrue);
    expect(hm(reminders.first.at), '07:45');
  });
}
