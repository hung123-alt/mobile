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

  // LOP 5 - DANH SACH DOMAIN DUOC PHEP NHUNG VIDEO (P2).
  //
  // VÌ SAO CAN?
  // - WebView bat JavaScriptMode.unrestricted thi trang embed co the chay
  //   bat ky JS nao (dao coin, phishing, chuyen huong). Gioi han domain
  //   la lop phong thu re nhat: chi host co trong seed/backend moi duoc mo.
  // - Mobile khong dung chung WebView nay de render HTML tu server.
  static const List<String> _allowedEmbedHosts = <String>[
    'www.youtube.com', // Server 2 = link YouTube backup (seed.sql)
    'youtube.com',
    'youtu.be',
    'www.youtube-nocookie.com',
    'player.vimeo.com', // du phong neu sau nay them Vimeo
    'player.twitch.tv', // du phong neu sau nay them Twitch
  ];

  /// true neu URL thuoc host duoc phep (khong phan biet hoa thuong).
  /// Chan luon scheme nguy hiem: file://, javascript:, data:.
  static bool isEmbedUrlAllowed(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;
    if (uri.scheme != 'https') return false; // LOP 4: embed bat buoc https
    final host = uri.host.toLowerCase();
    return _allowedEmbedHosts.any(
      (allowed) => host == allowed || host.endsWith('.$allowed'),
    );
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _MobileEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl && _controller != null) {
      // LOP 5: URL moi cung phai qua white-list, tranh doi embed giua chung.
      if (!isEmbedUrlAllowed(widget.embedUrl)) {
        debugPrint('MobileEmbedPlayer: chan embed URL doi giua chung');
        return;
      }
      setState(() => _isLoading = true);
      final uri = Uri.tryParse(widget.embedUrl);
      if (uri != null) {
        _controller!.loadRequest(uri);
      }
    }
  }

  void _initController() {
    if (!_isSupportedMobile) return;

    // LOP 5: chan ngay tu dau neu URL khong thuoc domain cho phep.
    if (!isEmbedUrlAllowed(widget.embedUrl)) {
      debugPrint('MobileEmbedPlayer: chan embed URL khong hop le');
      return; // _controller giu null -> UI hien thong bao thay vi WebView
    }

    final uri = Uri.tryParse(widget.embedUrl);
    if (uri == null) return;

    final ctrl = WebViewController()
      // LOP 5: chi WebView PHIM moi duoc unrestricted. Khong dung che do
      // nay cho bat ky WebView nao khac (VD hien thi noi dung server).
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
          // LOP 5: chan chuyen huong ra ngoai + chan cua so moi.
          // WebView khong ho tro new window: moi URL khong thuoc
          // white-list deu bi prevent (ngan phishing/chuyen huong doc hai).
          onNavigationRequest: (request) {
            if (!isEmbedUrlAllowed(request.url)) {
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

