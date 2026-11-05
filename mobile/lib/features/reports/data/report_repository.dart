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

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.completionPercent,
    required this.totalHabits,
    required this.streak,
    required this.completed,
    required this.missed,
    required this.trend,
  });

  final String month;
  final int completionPercent;
  final int totalHabits;
  final int streak;
  final int completed;
  final int missed;
  final List<TrendPoint> trend;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        month: json['month'] as String,
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

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  /// [month] is formatted as yyyy-MM.
  Future<MonthlyReport> monthly(String month) => guardApi(() async {
        final res = await _dio.get('/reports', queryParameters: {
          'month': month,
          'date': Fmt.apiDate(DateTime.now()),
        });
        return MonthlyReport.fromJson(res.data['data'] as Map<String, dynamic>);
      });
}
