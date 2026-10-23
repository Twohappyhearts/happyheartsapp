// Mobile implementation of the SoundCloud audio player (non-web platforms).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'media_webview.dart';

/// [onState] receives SoundCloud Widget API events: play | pause | ended.
Object? createSoundCloudController(
  String trackUrl, {
  void Function(String state)? onState,
}) {
  final controller = createMediaWebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel(
      'HHTrack',
      onMessageReceived: (message) => onState?.call(message.message),
    )
    ..loadHtmlString(_buildSoundCloudHtml(trackUrl), baseUrl: kEmbedPageOrigin);
  return controller;
}

String _buildSoundCloudHtml(String trackUrl) {
  final src = Uri.https('w.soundcloud.com', '/player/', {
    'url': trackUrl,
    'color': '#3b82f6',
    'auto_play': 'false',
    'hide_related': 'true',
    'show_comments': 'false',
    'show_user': 'true',
    'show_reposts': 'false',
    'show_teaser': 'false',
    'visual': 'false',
  }).toString();
  // HTML-escape the attribute value.
  final escaped = const HtmlEscape(HtmlEscapeMode.attribute).convert(src);
  return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #fff; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <iframe id="sc" scrolling="no" frameborder="no" allow="autoplay" src="$escaped"></iframe>
  <script src="https://w.soundcloud.com/player/api.js"></script>
  <script>
    // Listening-time tracking. If the API can't load, the player still works.
    function hhPost(s) {
      try { if (window.HHTrack) HHTrack.postMessage(s); } catch (e) {}
    }
    try {
      var w = SC.Widget(document.getElementById('sc'));
      w.bind(SC.Widget.Events.PLAY, function () { hhPost('play'); });
      w.bind(SC.Widget.Events.PAUSE, function () { hhPost('pause'); });
      w.bind(SC.Widget.Events.FINISH, function () { hhPost('ended'); });
    } catch (e) {}
  </script>
</body>
</html>''';
}

Widget buildSoundCloudPlayer(String trackUrl, Object? mobileController) {
  if (mobileController != null) {
    return WebViewWidget(controller: mobileController as WebViewController);
  }
  return const SizedBox.shrink();
}
