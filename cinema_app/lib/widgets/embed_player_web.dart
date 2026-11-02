import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../core/utils/video_source.dart';

final Set<String> _registeredViewTypes = <String>{};

Widget buildPlatformEmbedPlayer(String embedUrl) {
  final normalized = VideoSource.normalize(embedUrl);
  final viewType = 'cinema-embed-${normalized.hashCode}';

  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = normalized
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#000000'
        ..allowFullscreen = true
        ..allow = 'autoplay; fullscreen; encrypted-media; picture-in-picture';
      return iframe;
    });
  }

  return HtmlElementView(
    key: ValueKey(viewType),
    viewType: viewType,
  );
}
