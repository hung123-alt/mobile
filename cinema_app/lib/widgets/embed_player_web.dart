import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = <String>{};

Widget buildPlatformEmbedPlayer(String embedUrl) {
  final viewType = 'cinema-embed-${embedUrl.hashCode}';

  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = embedUrl
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

