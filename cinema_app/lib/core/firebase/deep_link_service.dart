import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

/// Bắt deep link `cinemahay24h://reset-password?...` khi user bấm link

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  /// Navigator key toàn cục để điều hướng từ stream (ngoài BuildContext).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// Gọi 1 lần trong `main()` sau `Firebase.initializeApp`.
  Future<void> init() async {
    if (_started) return;
    _started = true;

    // App đang chạy (background/foreground): nghe link mới.
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => debugPrint('DeepLink stream error: $e'),
    );

    // App bị kill rồi mở bằng link (cold start): lấy link đầu tiên.
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) {
        // Đợi MaterialApp gắn navigatorKey xong mới push.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _handleUri(initial);
      }
    } catch (e) {
      debugPrint('DeepLink getInitialLink error: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  /// Tách `oobCode` từ mọi dạng link Firebase có thể gửi:
  /// - `cinemahay24h://reset-password?oobCode=...&mode=resetPassword`
  /// - link `https://*.firebaseapp.com/__/auth/action?...&continueUrl=cinemahay24h://...`
  /// - link lồng trong tham số `link` (Dynamic/Hosting link).
  void _handleUri(Uri uri) {
    final String? oobCode = _extractOobCode(uri);
    if (oobCode == null || oobCode.isEmpty) return;
    if (!_isResetMode(uri)) return;

    navigatorKey.currentState?.pushNamed(
      AppRoutes.resetPassword,
      arguments: <String, String>{'oobCode': oobCode},
    );
  }

  bool _isResetMode(Uri uri) {
    if (uri.queryParameters['mode'] == 'resetPassword') return true;
    for (final value in uri.queryParameters.values) {
      final nested = _tryParseHttp(value);
      if (nested != null && nested.queryParameters['mode'] == 'resetPassword') {
        return true;
      }
    }
    // Custom scheme của ta chỉ dùng cho reset nên chấp nhận luôn
    // khi host khớp, kể cả khi Firebase không gắn `mode`.
    if (uri.scheme == 'cinemahay24h' && uri.host == 'reset-password') {
      return true;
    }
    return false;
  }

  String? _extractOobCode(Uri uri) {
    final direct = uri.queryParameters['oobCode'];
    if (direct != null && direct.isNotEmpty) return direct;
    for (final key in <String>['link', 'continueUrl', 'continue-url']) {
      final nestedRaw = uri.queryParameters[key];
      final nested = _tryParseHttp(nestedRaw);
      final code = nested?.queryParameters['oobCode'];
      if (code != null && code.isNotEmpty) return code;
    }
    return null;
  }

  Uri? _tryParseHttp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Uri.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
