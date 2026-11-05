import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../habits/data/habit.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) => ContentRepository(ref.watch(dioProvider)));

class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.fileUrl,
    this.videoUrl,
    this.youtubeId,
    this.thumbnailUrl,
  });

  final int id;
  final String type;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? videoUrl;
  final String? youtubeId;
  final String? thumbnailUrl;

  bool get isVideo => type == 'video';
  bool get isYoutube => youtubeId != null;

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    String? media(String key) => json[key] == null ? null : Env.resolveMediaUrl(json[key] as String);
    return GalleryItem(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: media('file_url'),
      videoUrl: json['video_url'] as String?,
      youtubeId: json['youtube_id'] as String?,
      thumbnailUrl: media('thumbnail_url'),
    );
  }
}

class Announcement {
  const Announcement({required this.id, required this.title, required this.body, this.publishedAt, required this.isRead});

  final int id;
  final String title;
  final String body;
  final DateTime? publishedAt;
  final bool isRead;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        publishedAt: json['published_at'] == null ? null : DateTime.parse(json['published_at'] as String).toLocal(),
        isRead: json['is_read'] as bool? ?? false,
      );
}

class AnnouncementFeed {
  const AnnouncementFeed({required this.items, required this.unreadCount});

  final List<Announcement> items;
  final int unreadCount;
}

/// Reminder rules set by the superadmin in the web panel.
class ReminderSettings {
  const ReminderSettings({this.defaultOn = true, this.leadMinutes = 15, this.intervalMinutes = 15});

  final bool defaultOn;
  final int leadMinutes;
  final int intervalMinutes;

  factory ReminderSettings.fromJson(Map<String, dynamic> json) => ReminderSettings(
        defaultOn: json['reminders_default_on'] as bool? ?? true,
        leadMinutes: toInt(json['reminder_lead_minutes']) ?? 15,
        intervalMinutes: toInt(json['reminder_interval_minutes']) ?? 15,
      );
}

class ContentRepository {
  ContentRepository(this._dio);

  final Dio _dio;

  Future<List<GalleryItem>> gallery({String? type}) => guardApi(() async {
        final res = await _dio.get('/gallery', queryParameters: {'type': ?type});
        return (res.data['data'] as List).map((e) => GalleryItem.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<AnnouncementFeed> announcements() => guardApi(() async {
        final res = await _dio.get('/announcements');
        return AnnouncementFeed(
          items: (res.data['data'] as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList(),
          unreadCount: toInt(res.data['unread_count']) ?? 0,
        );
      });

  Future<void> markAllAnnouncementsRead() => guardApi(() => _dio.post('/announcements/read-all'));

  /// Master habit templates share the habit JSON shape.
  Future<List<Habit>> masterHabits() => guardApi(() async {
        final res = await _dio.get('/master-habits');
        return (res.data['data'] as List).map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> adoptMasterHabits(List<int> ids) =>
      guardApi(() => _dio.post('/habits/from-master', data: {'master_habit_ids': ids}));

  Future<ReminderSettings> reminderSettings() => guardApi(() async {
        final res = await _dio.get('/settings/app');
        return ReminderSettings.fromJson(res.data['data'] as Map<String, dynamic>);
      });
}
