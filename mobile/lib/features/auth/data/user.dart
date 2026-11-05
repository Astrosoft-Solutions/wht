import '../../../core/config/env.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    this.avatarUrl,
    this.role = 'coach',
    this.coachType,
    this.planName,
    this.planTier,
  });

  final int id;
  final String name;
  final String email;
  final String? mobile;
  final String? avatarUrl;
  final String role;

  /// consultant, coach or guide.
  final String? coachType;
  final String? planName;
  final String? planTier;

  bool get isSuperadmin => role == 'superadmin';

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final plan = subscription?['plan'] as Map<String, dynamic>?;
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String?,
      avatarUrl: json['avatar_url'] == null ? null : Env.resolveMediaUrl(json['avatar_url'] as String),
      role: json['role'] as String? ?? 'coach',
      coachType: json['coach_type'] as String?,
      planName: plan?['name'] as String?,
      planTier: plan?['tier'] as String?,
    );
  }
}
