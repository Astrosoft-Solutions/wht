import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_habit_tracker/core/config/env.dart';
import 'package:wellness_habit_tracker/core/utils/formatters.dart';
import 'package:wellness_habit_tracker/features/customers/data/customer_models.dart';

void main() {
  test('time range collapses a shared AM/PM suffix', () {
    expect(Fmt.timeRange('04:20', '04:45'), '4:20 – 4:45 AM');
    expect(Fmt.timeRange('11:00', '12:30'), '11:00 AM – 12:30 PM');
    expect(Fmt.timeRange('04:00', null), '4:00 AM');
  });

  test('BMI is calculated from weight and height', () {
    expect(calculateBmi(72, 165), 26.4);
    expect(calculateBmi(null, 165), isNull);
  });

  test('localhost media URLs are rewritten to the API host', () {
    final api = Uri.parse(Env.apiBaseUrl);
    final resolved = Uri.parse(Env.resolveMediaUrl('http://localhost:8000/storage/customers/1/a.jpg'));
    expect(resolved.host, api.host);
    expect(resolved.path, '/storage/customers/1/a.jpg');
    expect(Env.resolveMediaUrl('https://lh3.googleusercontent.com/a.jpg'), 'https://lh3.googleusercontent.com/a.jpg');
  });
}
