import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'skeleton.dart';

/// Network image that caches on mobile. On web it falls back to an HTML <img> element,
/// because uploaded files served from /storage carry no CORS headers.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const placeholder = Shimmering(child: SkeletonBox(height: double.infinity, radius: 0));
    final error = Container(
      color: context.palette.surfaceMuted,
      child: Center(child: Icon(Icons.broken_image_outlined, color: context.palette.textSecondary)),
    );

    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => error,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => error,
    );
  }
}
