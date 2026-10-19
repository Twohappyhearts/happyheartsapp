// Mobile implementation for YouTube video player (non-web platforms)
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Object? createYouTubeController(String videoId) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setUserAgent(
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    )
    ..loadHtmlString(_buildYouTubeHtml(videoId));
  return controller;
}

String _buildYouTubeHtml(String videoId) {
  return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    .container { position: relative; width: 100%; height: 100%; }
    iframe {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      border: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <iframe
      src="https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&playsinline=1"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
      allowfullscreen
      frameborder="0">
    </iframe>
  </div>
</body>
</html>''';
}

Widget buildVideoPlayer(String videoId, Object? mobileController) {
  if (mobileController != null) {
    return WebViewWidget(controller: mobileController as WebViewController);
  }
  return Container(color: Colors.black);
}
