import 'package:flutter/material.dart';

import 'embed_player_stub.dart'
    if (dart.library.js_interop) 'embed_player_web.dart'
    if (dart.library.io) 'embed_player_mobile.dart';

/// Widget phát phim nhúng (Embed Player) đa nền tảng:
/// - Trên Web: sử dụng `<iframe>` (`HtmlElementView`).
/// - Trên Android / iOS: sử dụng `WebViewWidget` (`webview_flutter`).
class EmbedVideoPlayer extends StatelessWidget {
  final String embedUrl;

  const EmbedVideoPlayer({
    super.key,
    required this.embedUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = embedUrl.trim();
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

    return buildPlatformEmbedPlayer(cleanUrl);
  }
}

