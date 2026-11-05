import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/content_repository.dart';
import '../providers/content_providers.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the list counts as reading everything in it, which also clears the dashboard badge.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(contentRepositoryProvider).markAllAnnouncementsRead();
        if (mounted) ref.invalidate(announcementsProvider);
      } catch (_) {
        // Unread state is cosmetic; keep showing the list.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: feed.when(
        loading: () => const Shimmering(
          child: Padding(
            padding: EdgeInsets.all(Gaps.l),
            child: Column(children: [SkeletonCard(height: 110), SkeletonCard(height: 110), SkeletonCard(height: 110)]),
          ),
        ),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(announcementsProvider)),
        data: (data) => data.items.isEmpty
            ? const EmptyView(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
                message: 'News and updates from the team will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(announcementsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _AnnouncementCard(item: data.items[i]).staggered(i),
                ),
              ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: Icons.campaign_rounded, color: item.isRead ? p.textSecondary : AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                      if (!item.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  if (item.publishedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, h:mm a').format(item.publishedAt!),
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(item.body, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
