import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';

/// Keyed by month in yyyy-MM format.
final monthlyReportProvider = FutureProvider.autoDispose.family<MonthlyReport, String>(
  (ref, month) => ref.watch(reportRepositoryProvider).monthly(month),
);
