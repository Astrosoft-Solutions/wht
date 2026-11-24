import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/data/user.dart';
import 'habit.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) => HabitRepository(ref.watch(dioProvider)));

class Dashboard {
  const Dashboard({
    required this.user,
    required this.date,
    required this.total,
    required this.completed,
    required this.percent,
    required this.streak,
    required this.schedule,
  });

  final AppUser user;
  final DateTime date;
  final int total;
  final int completed;
  final int percent;
  final int streak;
  final List<Habit> schedule;
}

class HabitRepository {
  HabitRepository(this._dio);

  final Dio _dio;

  /// Uses the device's calendar date so "today" matches what the user sees.
  String get _today => Fmt.apiDate(DateTime.now());

  Future<Dashboard> dashboard() => guardApi(() async {
        final res = await _dio.get('/dashboard', queryParameters: {'date': _today});
        final d = res.data as Map<String, dynamic>;
        return Dashboard(
          user: AppUser.fromJson(d['user'] as Map<String, dynamic>),
          date: Fmt.parseDate(d['date'] as String),
          total: toInt(d['habits_total']) ?? 0,
          completed: toInt(d['habits_completed']) ?? 0,
          percent: toInt(d['completion_percent']) ?? 0,
          streak: toInt(d['streak']) ?? 0,
          schedule: _habits(d['schedule']),
        );
      });

  Future<List<Habit>> all() => guardApi(() async {
        final res = await _dio.get('/habits');
        return _habits(res.data['data']);
      });

  Future<HabitSchedule> schedule(HabitRange range) => guardApi(() async {
        final res = await _dio.get('/habits/schedule', queryParameters: {'range': range.apiValue, 'date': _today});
        return HabitSchedule(range: range, habits: _habits(res.data['data']));
      });

  /// Returns today's totals after the change.
  Future<DayStats> toggle(int habitId) => guardApi(() async {
        final res = await _dio.post('/habits/$habitId/toggle', data: {'date': _today});
        return DayStats.fromJson(res.data['stats'] as Map<String, dynamic>);
      });

  Future<DayStats> completeAll() => guardApi(() async {
        final res = await _dio.post('/habits/complete-all', data: {'date': _today});
        return DayStats.fromJson(res.data['stats'] as Map<String, dynamic>);
      });

  Future<Habit> create(HabitInput input) => guardApi(() async {
        final res = await _dio.post('/habits', data: input.toJson());
        return Habit.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<Habit> update(int id, HabitInput input) => guardApi(() async {
        final res = await _dio.put('/habits/$id', data: input.toJson());
        return Habit.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<void> delete(int id) => guardApi(() => _dio.delete('/habits/$id'));

  List<Habit> _habits(dynamic list) =>
      (list as List).map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
}
