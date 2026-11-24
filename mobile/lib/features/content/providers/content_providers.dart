import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/data/habit.dart';
import '../data/content_repository.dart';

/// Keyed by type: '' for all, 'image' or 'video'.
final galleryProvider = FutureProvider.autoDispose.family<List<GalleryItem>, String>(
  (ref, type) => ref.watch(contentRepositoryProvider).gallery(type: type.isEmpty ? null : type),
);

final announcementsProvider = FutureProvider.autoDispose<AnnouncementFeed>(
  (ref) => ref.watch(contentRepositoryProvider).announcements(),
);

final masterHabitsProvider = FutureProvider.autoDispose<List<Habit>>(
  (ref) => ref.watch(contentRepositoryProvider).masterHabits(),
);
