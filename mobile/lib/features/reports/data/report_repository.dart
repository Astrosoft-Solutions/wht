import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository(ref.watch(dioProvider)));

class TrendPoint {
  const TrendPoint({required this.date, required this.total, required this.completed, required this.percent});

  final DateTime date;
  final int total;
  final int completed;
  final int percent;
}

class HabitReport {
  const HabitReport({
    required this.month,
    required this.from,
    required this.to,
    required this.completionPercent,
    required this.totalHabits,
    required this.streak,
    required this.completed,
    required this.missed,
    required this.trend,
  });

  final String month;
  final DateTime from;
  final DateTime to;
  final int completionPercent;
  final int totalHabits;
  final int streak;
  final int completed;
  final int missed;
  final List<TrendPoint> trend;

  factory HabitReport.fromJson(Map<String, dynamic> json) {
    final month = json['month'] as String? ?? '';
    final from = json['from'] != null
        ? Fmt.parseDate(json['from'] as String)
        : Fmt.parseDate('$month-01');
    final to = json['to'] != null ? Fmt.parseDate(json['to'] as String) : from;

    return HabitReport(
      month: month.isNotEmpty ? month : Fmt.apiMonth(from),
      from: from,
      to: to,
      completionPercent: toInt(json['completion_percent']) ?? 0,
      totalHabits: toInt(json['total_habits']) ?? 0,
      streak: toInt(json['streak']) ?? 0,
      completed: toInt(json['completed']) ?? 0,
      missed: toInt(json['missed']) ?? 0,
      trend: (json['trend'] as List)
          .map((e) => TrendPoint(
                date: Fmt.parseDate(e['date'] as String),
                total: toInt(e['total']) ?? 0,
                completed: toInt(e['completed']) ?? 0,
                percent: toInt(e['percent']) ?? 0,
              ))
          .toList(),
    );
  }
}

/// Kept for older call sites / tests that still reference the previous name.
typedef MonthlyReport = HabitReport;

class ReportRange {
  const ReportRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  String get key => '${Fmt.apiDate(from)}_${Fmt.apiDate(to)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReportRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  Future<HabitReport> forRange(ReportRange range) => guardApi(() async {
        final res = await _dio.get('/reports', queryParameters: {
          'from': Fmt.apiDate(range.from),
          'to': Fmt.apiDate(range.to),
          'date': Fmt.apiDate(DateTime.now()),
        });
        return HabitReport.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  /// [month] is formatted as yyyy-MM.
  Future<HabitReport> monthly(String month) => guardApi(() async {
        final res = await _dio.get('/reports', queryParameters: {
          'month': month,
          'date': Fmt.apiDate(DateTime.now()),
        });
        return HabitReport.fromJson(res.data['data'] as Map<String, dynamic>);
      });
}
