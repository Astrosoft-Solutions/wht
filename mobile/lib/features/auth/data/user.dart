import '../../../core/config/env.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    this.avatarUrl,
    this.avatarCacheKey,
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

  /// Busts stale avatar caches after a re-upload (from `updated_at`).
  final String? avatarCacheKey;
  final String role;

  /// consultant, coach or guide.
  final String? coachType;
  final String? planName;
  final String? planTier;

  bool get isSuperadmin => role == 'superadmin';

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// Remote avatar URL with a cache-buster query when [avatarCacheKey] is set.
  String? get avatarDisplayUrl {
    final url = avatarUrl;
    if (url == null) return null;
    final key = avatarCacheKey;
    if (key == null || key.isEmpty) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(queryParameters: {...uri.queryParameters, 'v': key}).toString();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final plan = subscription?['plan'] as Map<String, dynamic>?;
    final updatedAt = json['updated_at'] as String?;
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String?,
      avatarUrl: json['avatar_url'] == null ? null : Env.resolveMediaUrl(json['avatar_url'] as String),
      avatarCacheKey: updatedAt,
      role: json['role'] as String? ?? 'coach',
      coachType: json['coach_type'] as String?,
      planName: plan?['name'] as String?,
      planTier: plan?['tier'] as String?,
    );
  }
}
