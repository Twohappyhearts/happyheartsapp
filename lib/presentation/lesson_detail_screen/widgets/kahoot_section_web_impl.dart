// Web implementation for Kahoot embed — web platform only
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

Object? createKahootController(String kahootUrl) {
  // Web platform: no controller needed
  return null;
}

Widget buildKahootPlayer(String kahootUrl, Object? mobileController) {
  final safeKey = kahootUrl.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  final viewType = 'kahoot-iframe-$safeKey';
  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (
      int viewId, {
      Object? params,
    }) {
      final iframe = web.HTMLIFrameElement()
        ..src = kahootUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; microphone; camera'
        ..setAttribute('allowfullscreen', '');
      return iframe;
    });
  } catch (_) {
    // Already registered — ignore
  }
  return HtmlElementView(viewType: viewType);
}
