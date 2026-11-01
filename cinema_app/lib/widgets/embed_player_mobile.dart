import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _MobileEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl && _controller != null) {
      setState(() => _isLoading = true);
      final uri = Uri.tryParse(widget.embedUrl);
      if (uri != null) {
        _controller!.loadRequest(uri);
      }
    }
  }

  void _initController() {
    if (!_isSupportedMobile) return;

    final uri = Uri.tryParse(widget.embedUrl);
    if (uri == null) return;

    final ctrl = WebViewController()
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
        ),
      )
      ..loadRequest(uri);

    _controller = ctrl;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedMobile || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Đang phát nguồn: ${widget.embedUrl}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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

