// Mobile implementation for YouTube video player (non-web platforms)
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'media_webview.dart';

/// [onState] receives player states posted by the YouTube IFrame Player API:
/// play | playing | buffer | pause | ended (used for watch-time analytics).
Object? createYouTubeController(
  String videoId, {
  void Function(String state)? onState,
}) {
  final controller = createMediaWebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel(
      'HHTrack',
      onMessageReceived: (message) => onState?.call(message.message),
    )
    ..setUserAgent(
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    )
    // baseUrl gives the page an origin -> YouTube gets a Referer (no Error 153).
    ..loadHtmlString(_buildYouTubeHtml(videoId), baseUrl: kEmbedPageOrigin);
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
      id="yt"
      src="https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&playsinline=1&enablejsapi=1&origin=${Uri.encodeComponent(kEmbedPageOrigin)}&widget_referrer=${Uri.encodeComponent(kEmbedPageOrigin)}"
      referrerpolicy="strict-origin-when-cross-origin"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
      allowfullscreen
      frameborder="0">
    </iframe>
  </div>
  <script>
    // Watch-time tracking. If the API script can't load, the video still plays.
    var hhActive = false;
    function hhPost(s) {
      try { if (window.HHTrack) HHTrack.postMessage(s); } catch (e) {}
    }
    function onYouTubeIframeAPIReady() {
      new YT.Player('yt', { events: { onStateChange: function (e) {
        var s = e.data;
        if (s === 1) { hhPost(hhActive ? 'playing' : 'play'); hhActive = true; }
        else if (s === 3) { if (hhActive) hhPost('buffer'); }
        else if (s === 2 || s === 0) {
          if (hhActive) { hhActive = false; hhPost(s === 0 ? 'ended' : 'pause'); }
        }
      } } });
    }
  </script>
  <script src="https://www.youtube.com/iframe_api" async></script>
</body>
</html>''';
}

Widget buildVideoPlayer(String videoId, Object? mobileController) {
  if (mobileController != null) {
    return WebViewWidget(controller: mobileController as WebViewController);
  }
  return Container(color: Colors.black);
}
