import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _apiDate = DateFormat('yyyy-MM-dd');
  static final _apiMonth = DateFormat('yyyy-MM');

  static String apiDate(DateTime date) => _apiDate.format(date);
  static String apiMonth(DateTime date) => _apiMonth.format(date);
  static DateTime parseDate(String value) => _apiDate.parse(value);

  /// "Tue, 04 Nov 2026"
  static String chipDate(DateTime date) => DateFormat('EEE, dd MMM yyyy').format(date);

  /// "01 Nov"
  static String shortDate(DateTime date) => DateFormat('dd MMM').format(date);

  /// "Nov 2026"
  static String monthYear(DateTime date) => DateFormat('MMM yyyy').format(date);

  /// "01 Nov – 22 Nov 2026" (collapses year/month when shared).
  static String dateRange(DateTime from, DateTime to) {
    final sameYear = from.year == to.year;
    final sameMonth = sameYear && from.month == to.month;
    if (sameMonth) {
      return '${DateFormat('dd').format(from)} – ${DateFormat('dd MMM yyyy').format(to)}';
    }
    if (sameYear) {
      return '${DateFormat('dd MMM').format(from)} – ${DateFormat('dd MMM yyyy').format(to)}';
    }
    return '${DateFormat('dd MMM yyyy').format(from)} – ${DateFormat('dd MMM yyyy').format(to)}';
  }

  /// "04:00" -> "4:00 AM"
  static String time(String hhmm) {
    final parts = hhmm.split(':');
    final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('h:mm a').format(dt);
  }

  /// "4:20 – 4:45 AM", or "4:00 AM" when there is no end time.
  static String timeRange(String start, String? end) {
    if (end == null) return time(start);
    final s = time(start);
    final e = time(end);
    final sameMeridiem = s.substring(s.length - 2) == e.substring(e.length - 2);
    return sameMeridiem ? '${s.substring(0, s.length - 3)} – $e' : '$s – $e';
  }

  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good Morning';
    if (now.hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String num1(double? value) => value == null ? '-' : value.toStringAsFixed(1);

  static String numOrDash(num? value) {
    if (value == null) return '-';
    if (value is int || value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

double? toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? toInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
