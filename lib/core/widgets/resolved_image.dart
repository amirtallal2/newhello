import 'package:flutter/material.dart';

import '../config/api_config.dart';

String resolveMediaUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  final origin = ApiConfig.origin();
  if (path.startsWith('/')) {
    return '$origin$path';
  }

  return '$origin/$path';
}

ImageProvider<Object> resolvedImageProvider(String path) {
  final resolvedPath = path.trim();
  if (resolvedPath.startsWith('assets/')) {
    return AssetImage(resolvedPath);
  }

  return NetworkImage(resolveMediaUrl(resolvedPath));
}

Future<void> precacheResolvedImage(BuildContext context, String path) async {
  final resolvedPath = path.trim();
  if (resolvedPath.isEmpty) {
    return;
  }

  try {
    await precacheImage(resolvedImageProvider(resolvedPath), context);
  } catch (_) {
    // Failed media should not block the main live/gift flow.
  }
}

class ResolvedImage extends StatelessWidget {
  const ResolvedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final resolvedPath = path.trim();
    if (resolvedPath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE9EEF4),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Color(0xFF285F98),
        ),
      );
    }

    if (resolvedPath.startsWith('assets/')) {
      return Image.asset(
        resolvedPath,
        width: width,
        height: height,
        fit: fit,
        filterQuality: filterQuality,
        gaplessPlayback: true,
      );
    }

    return Image.network(
      resolveMediaUrl(resolvedPath),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF4),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFE9EEF4),
          alignment: Alignment.center,
          child: const Icon(Icons.person_rounded, color: Color(0xFF285F98)),
        );
      },
    );
  }
}
