import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/utils/video_source.dart';

Widget buildPlatformEmbedPlayer(String embedUrl) {
  return _MobileEmbedPlayer(embedUrl: embedUrl);
}

class _MobileEmbedPlayer extends StatefulWidget {
  final String embedUrl;

  const _MobileEmbedPlayer({
    required this.embedUrl,
  });

  @override
  State<_MobileEmbedPlayer> createState() => _MobileEmbedPlayerState();
}

class _MobileEmbedPlayerState extends State<_MobileEmbedPlayer> {
  WebViewController? _controller;
  bool _isLoading = true;

  bool get _isSupportedMobile => Platform.isAndroid || Platform.isIOS;

  /// Giữ tên hàm cũ để code nơi khác (nếu có) vẫn gọi được.
  /// Delegation sang [VideoSource.isSupported] — chấp nhận mọi link https
  /// do admin nhập (VSMOV / YouTube / mp4 / m3u8 / embed...), chỉ chặn
  /// scheme nguy hiểm. Whitelist cứng cũ là nguyên nhân link VSMOV
  /// bị trắng màn hình.
  static bool isEmbedUrlAllowed(String rawUrl) =>
      VideoSource.isSupported(rawUrl);

  String get _normalizedUrl => VideoSource.normalize(widget.embedUrl);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _MobileEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl && _controller != null) {
      if (!isEmbedUrlAllowed(widget.embedUrl)) {
        debugPrint('MobileEmbedPlayer: chan embed URL doi giua chung');
        return;
      }
      setState(() => _isLoading = true);
      final uri = Uri.tryParse(_normalizedUrl);
      if (uri != null) {
        _controller!.loadRequest(uri);
      }
    }
  }

  void _initController() {
    if (!_isSupportedMobile) return;

    if (!isEmbedUrlAllowed(widget.embedUrl)) {
      debugPrint(
        'MobileEmbedPlayer: chan embed URL khong hop le: ${widget.embedUrl}',
      );
      return;
    }

    final uri = Uri.tryParse(_normalizedUrl);
    if (uri == null) return;

    final ctrl = WebViewController()
      // Chỉ WebView PHIM mới được unrestricted. Không dùng chế độ
      // này cho bất kỳ WebView nào khác (VD hiển thị nội dung server).
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('MobileEmbedPlayer resource error: $error');
            if (mounted) setState(() => _isLoading = false);
          },
          // Chặn điều hướng nguy hiểm + cửa sổ mới, nhưng cho phép
          // điều hướng https nội bộ của trang nhúng (VSMOV/YouTube
          // hay chuyển hướng qua CDN của họ). Chỉ prevent khi gặp
          // scheme lạ (file://, javascript:, data:, blob:...).
          onNavigationRequest: (request) {
            final lower = request.url.trim().toLowerCase();
            if (lower.startsWith('javascript:') ||
                lower.startsWith('data:') ||
                lower.startsWith('file:') ||
                lower.startsWith('blob:')) {
              debugPrint(
                'MobileEmbedPlayer: prevent navigation toi ${request.url}',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(uri);

    _controller = ctrl;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedMobile || _controller == null) {
      final ok = VideoSource.isSupported(widget.embedUrl);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok
                    ? Icons.play_circle_outline_rounded
                    : Icons.link_off_rounded,
                color: Colors.white70,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                ok
                    ? 'Đang tải nguồn phát...'
                    : 'Link phát chưa hợp lệ:\n${widget.embedUrl}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF4B5C),
            ),
          ),
      ],
    );
  }
}
