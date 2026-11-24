import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';

final reportProvider = FutureProvider.autoDispose.family<HabitReport, ReportRange>(
  (ref, range) => ref.watch(reportRepositoryProvider).forRange(range),
);

/// Keyed by month in yyyy-MM format.
@Deprecated('Use reportProvider with a ReportRange instead')
final monthlyReportProvider = FutureProvider.autoDispose.family<HabitReport, String>(
  (ref, month) => ref.watch(reportRepositoryProvider).monthly(month),
);
