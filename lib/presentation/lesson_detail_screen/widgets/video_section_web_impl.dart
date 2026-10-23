// Web implementation for video player — web platform only
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

// This file is only compiled on web — no webview_flutter needed
Object? createYouTubeController(
  String videoId, {
  void Function(String state)? onState, // not tracked on web
}) {
  // Web platform: no controller needed, iframe is registered directly
  return null;
}

Widget buildVideoPlayer(String videoId, Object? mobileController) {
  // Register a unique view type per videoId
  final viewType = 'youtube-iframe-$videoId';
  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (
      int viewId, {
      Object? params,
    }) {
      final iframe = web.HTMLIFrameElement()
        ..src =
            'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&playsinline=1'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..setAttribute('allowfullscreen', '');
      return iframe;
    });
  } catch (_) {
    // Already registered — ignore
  }
  return HtmlElementView(viewType: viewType);
}
