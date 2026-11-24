import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/content_repository.dart';
import '../providers/content_providers.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  static const _tabs = [('', 'All'), ('image', 'Images'), ('video', 'Videos')];
  int _tab = 0;

  void _open(GalleryItem item) {
    if (item.isYoutube) {
      launchUrl(Uri.parse(item.videoUrl!), mode: LaunchMode.externalApplication);
    } else if (item.isVideo && item.fileUrl != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _VideoScreen(item: item)));
    } else if (item.fileUrl != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ImageScreen(item: item)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _tabs[_tab].$1;
    final gallery = ref.watch(galleryProvider(type));

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: PillTabs(labels: [for (final t in _tabs) t.$2], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
          ),
          Expanded(
            child: gallery.when(
              loading: () => const SkeletonGrid(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(galleryProvider(type))),
              data: (items) => items.isEmpty
                  ? const EmptyView(
                      icon: Icons.photo_library_outlined,
                      title: 'Nothing here yet',
                      message: 'New photos and videos from the team will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(galleryProvider(type).future),
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _GalleryTile(item: items[i], onTap: () => _open(items[i])).staggered(i),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.item, required this.onTap});

  final GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumbnailUrl != null)
                    Hero(tag: 'gallery-${item.id}', child: NetworkPhoto(url: item.thumbnailUrl!))
                  else
                    Container(color: context.palette.mint, child: Icon(Icons.movie_outlined, size: 40, color: context.palette.primary)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x55000000)],
                      ),
                    ),
                  ),
                  if (item.isVideo)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isYoutube ? Icons.smart_display_rounded : (item.isVideo ? Icons.videocam_rounded : Icons.image_rounded),
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.isYoutube ? 'YouTube' : (item.isVideo ? 'Video' : 'Photo'),
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageScreen extends StatelessWidget {
  const _ImageScreen({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(item.title, style: const TextStyle(color: Colors.white))),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(child: Hero(tag: 'gallery-${item.id}', child: NetworkPhoto(url: item.fileUrl!, fit: BoxFit.contain))),
            ),
          ),
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item.description!, style: const TextStyle(color: Colors.white70)),
            ),
        ],
      ),
    );
  }
}

class _VideoScreen extends StatefulWidget {
  const _VideoScreen({required this.item});

  final GalleryItem item;

  @override
  State<_VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<_VideoScreen> {
  late final VideoPlayerController _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.item.fileUrl!));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.play();
      }
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(widget.item.title, style: const TextStyle(color: Colors.white))),
      body: Center(
        child: _error != null
            ? const Text('This video could not be played.', style: TextStyle(color: Colors.white70))
            : !ready
                ? const DotsLoader()
                : GestureDetector(
                    onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          if (!_controller.value.isPlaying)
                            const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)),
                          VideoProgressIndicator(_controller, allowScrubbing: true),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
