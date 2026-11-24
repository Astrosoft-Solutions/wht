import '../../../core/utils/formatters.dart';

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.startTime,
    this.endTime,
    this.daysOfWeek,
    this.sortOrder = 0,
    this.isActive = true,
    this.isCompleted = false,
    this.isScheduledToday = true,
    this.completedCount,
    this.scheduledCount,
  });

  final int id;
  final String name;
  final String icon;
  final String color;
  final String startTime;
  final String? endTime;

  /// ISO weekdays (1 = Monday ... 7 = Sunday); null means every day.
  final List<int>? daysOfWeek;
  final int sortOrder;
  final bool isActive;
  final bool isCompleted;
  final bool isScheduledToday;
  final int? completedCount;
  final int? scheduledCount;

  String get timeLabel => Fmt.timeRange(startTime, endTime);

  Habit copyWith({bool? isCompleted}) => Habit(
        id: id,
        name: name,
        icon: icon,
        color: color,
        startTime: startTime,
        endTime: endTime,
        daysOfWeek: daysOfWeek,
        sortOrder: sortOrder,
        isActive: isActive,
        isCompleted: isCompleted ?? this.isCompleted,
        isScheduledToday: isScheduledToday,
        completedCount: completedCount,
        scheduledCount: scheduledCount,
      );

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'check',
        color: json['color'] as String? ?? '#2E7D32',
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String?,
        daysOfWeek: (json['days_of_week'] as List?)?.map((e) => toInt(e)!).toList(),
        sortOrder: toInt(json['sort_order']) ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        isCompleted: json['is_completed'] as bool? ?? false,
        isScheduledToday: json['is_scheduled_today'] as bool? ?? true,
        completedCount: toInt(json['completed_count']),
        scheduledCount: toInt(json['scheduled_count']),
      );
}

class HabitInput {
  const HabitInput({
    required this.name,
    required this.icon,
    required this.color,
    required this.startTime,
    this.endTime,
    this.daysOfWeek,
  });

  final String name;
  final String icon;
  final String color;
  final String startTime;
  final String? endTime;
  final List<int>? daysOfWeek;

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'color': color,
        'start_time': startTime,
        'end_time': endTime,
        'days_of_week': daysOfWeek,
      };
}

class DayStats {
  const DayStats({required this.total, required this.completed, required this.percent});

  final int total;
  final int completed;
  final int percent;

  factory DayStats.fromJson(Map<String, dynamic> json) => DayStats(
        total: toInt(json['total']) ?? 0,
        completed: toInt(json['completed']) ?? 0,
        percent: toInt(json['percent']) ?? 0,
      );
}

enum HabitRange {
  today('today', 'Today'),
  week('week', 'This Week'),
  month('month', 'This Month');

  const HabitRange(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class HabitSchedule {
  const HabitSchedule({required this.range, required this.habits});

  final HabitRange range;
  final List<Habit> habits;
}
