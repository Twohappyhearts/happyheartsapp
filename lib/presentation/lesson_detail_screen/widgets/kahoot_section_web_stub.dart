// Mobile implementation for Kahoot embed (non-web platforms)
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Object? createKahootController(String kahootUrl) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setUserAgent(
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    )
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) => NavigationDecision.navigate,
      ),
    )
    ..loadHtmlString(_buildKahootHtml(kahootUrl));
  return controller;
}

String _buildKahootHtml(String kahootUrl) {
  return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #46178f; overflow: hidden; }
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
      src="$kahootUrl"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen; microphone; camera"
      allowfullscreen
      frameborder="0">
    </iframe>
  </div>
</body>
</html>''';
}

Widget buildKahootPlayer(String kahootUrl, Object? mobileController) {
  if (mobileController != null) {
    return WebViewWidget(controller: mobileController as WebViewController);
  }
  return Container(color: const Color(0xFF46178f));
}
