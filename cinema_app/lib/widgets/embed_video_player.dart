import 'package:flutter/material.dart';

import '../core/utils/video_source.dart';
import 'embed_player_stub.dart'
    if (dart.library.js_interop) 'embed_player_web.dart'
    if (dart.library.io) 'embed_player_mobile.dart';

/// Widget phát phim nhúng (Embed Player) đa nền tảng:
/// - Trên Web: sử dụng `<iframe>` (`HtmlElementView`).
/// - Trên Android / iOS: sử dụng `WebViewWidget` (`webview_flutter`).
///
/// Mọi link đều qua [VideoSource.normalize] trước khi phát:
/// YouTube `watch?v=` / `youtu.be` / `shorts` -> `/embed/`,
/// còn VSMOV / mp4 / m3u8 / embed generic giữ nguyên.
class EmbedVideoPlayer extends StatelessWidget {
  final String embedUrl;

  const EmbedVideoPlayer({
    super.key,
    required this.embedUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = VideoSource.normalize(embedUrl);
    if (cleanUrl.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 42),
            SizedBox(height: 8),
            Text(
              'Tập phim này chưa có đường dẫn phát',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (!VideoSource.isSupported(cleanUrl)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded,
                  color: Colors.white54, size: 42),
              const SizedBox(height: 8),
              const Text(
                'Link phát chưa hợp lệ',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                embedUrl.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return buildPlatformEmbedPlayer(cleanUrl);
  }
}

