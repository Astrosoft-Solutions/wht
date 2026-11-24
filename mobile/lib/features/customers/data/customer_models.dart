import '../../../core/config/env.dart';
import '../../../core/utils/formatters.dart';

class Measurement {
  const Measurement({
    required this.id,
    required this.recordedOn,
    this.programmeId,
    this.weight,
    this.fatPercent,
    this.bmi,
    this.muscle,
    this.visceralFat,
    this.bodyAge,
    this.chest,
    this.waist,
    this.hp,
    this.rm24,
    this.totalPoints,
  });

  final int id;
  final DateTime recordedOn;
  final int? programmeId;
  final double? weight;
  final double? fatPercent;
  final double? bmi;
  final double? muscle;
  final double? visceralFat;
  final int? bodyAge;
  final double? chest;
  final double? waist;
  final String? hp;
  final String? rm24;
  final int? totalPoints;

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
        id: json['id'] as int,
        recordedOn: Fmt.parseDate(json['recorded_on'] as String),
        programmeId: toInt(json['programme_id']),
        weight: toDouble(json['weight']),
        fatPercent: toDouble(json['fat_percent']),
        bmi: toDouble(json['bmi']),
        muscle: toDouble(json['muscle']),
        visceralFat: toDouble(json['visceral_fat']),
        bodyAge: toInt(json['body_age']),
        chest: toDouble(json['chest']),
        waist: toDouble(json['waist']),
        hp: json['hp'] as String?,
        rm24: json['rm_24'] as String?,
        totalPoints: toInt(json['total_points']),
      );
}

class Programme {
  const Programme({
    required this.id,
    required this.name,
    this.goal,
    required this.totalWeeks,
    required this.weeksCompleted,
    required this.weeksRemaining,
    this.startDate,
  });

  final int id;
  final String name;
  final String? goal;
  final int totalWeeks;
  final int weeksCompleted;
  final int weeksRemaining;
  final DateTime? startDate;

  factory Programme.fromJson(Map<String, dynamic> json) => Programme(
        id: json['id'] as int,
        name: json['name'] as String,
        goal: json['goal'] as String?,
        totalWeeks: toInt(json['total_weeks']) ?? 0,
        weeksCompleted: toInt(json['weeks_completed']) ?? 0,
        weeksRemaining: toInt(json['weeks_remaining']) ?? 0,
        startDate: json['start_date'] == null ? null : Fmt.parseDate(json['start_date'] as String),
      );
}

class CustomerPhoto {
  const CustomerPhoto({required this.id, required this.type, required this.url, this.takenOn});

  final int id;
  final String type;
  final String url;
  final DateTime? takenOn;

  factory CustomerPhoto.fromJson(Map<String, dynamic> json) => CustomerPhoto(
        id: json['id'] as int,
        type: json['type'] as String,
        url: Env.resolveMediaUrl(json['url'] as String),
        takenOn: json['taken_on'] == null ? null : Fmt.parseDate(json['taken_on'] as String),
      );
}

class Customer {
  const Customer({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.heightCm,
    required this.status,
    this.healthConditionBefore,
    this.remarks,
    this.baseline,
    this.latest,
    this.programmes = const [],
    this.photos = const [],
  });

  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final double? heightCm;
  final String status;
  final String? healthConditionBefore;
  final String? remarks;
  final Measurement? baseline;
  final Measurement? latest;
  final List<Programme> programmes;
  final List<CustomerPhoto> photos;

  bool get isActive => status == 'active';

  CustomerPhoto? photo(String type) => photos.where((p) => p.type == type).firstOrNull;

  factory Customer.fromJson(Map<String, dynamic> json) {
    Measurement? measurement(String key) =>
        json[key] == null ? null : Measurement.fromJson(json[key] as Map<String, dynamic>);
    return Customer(
      id: json['id'] as int,
      code: json['customer_code'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      heightCm: toDouble(json['height_cm']),
      status: json['status'] as String? ?? 'active',
      healthConditionBefore: json['health_condition_before'] as String?,
      remarks: json['remarks'] as String?,
      baseline: measurement('baseline_measurement'),
      latest: measurement('latest_measurement'),
      programmes: ((json['programmes'] as List?) ?? const [])
          .map((e) => Programme.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: ((json['photos'] as List?) ?? const [])
          .map((e) => CustomerPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

double? calculateBmi(double? weightKg, double? heightCm) {
  if (weightKg == null || heightCm == null || heightCm <= 0) return null;
  final m = heightCm / 100;
  return double.parse((weightKg / (m * m)).toStringAsFixed(1));
}
