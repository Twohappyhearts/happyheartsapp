// Mobile-only helpers for the WebViews that play lesson media (YouTube,
// SoundCloud). Imported by the *_web_stub.dart files, never on Flutter web.
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Origin given to the HTML pages we build for embeds (loadHtmlString baseUrl).
///
/// Without a base URL the page has no origin, so the YouTube iframe is
/// requested without a Referer header and YouTube refuses to play it
/// ("Error 153 – video player configuration error"). It must be an https URL
/// that identifies the app (it does not need to resolve) and must NOT be a
/// YouTube domain (that gives Error 152).
const String kEmbedPageOrigin = 'https://io.happyhearts.app';

/// WebViewController that can play media inline and start playback without a
/// second tap (iOS otherwise forces full-screen and requires a user gesture).
WebViewController createMediaWebViewController() {
  PlatformWebViewControllerCreationParams params =
      const PlatformWebViewControllerCreationParams();
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  }
  final controller = WebViewController.fromPlatformCreationParams(params);
  final platform = controller.platform;
  if (platform is AndroidWebViewController) {
    platform.setMediaPlaybackRequiresUserGesture(false);
  }
  return controller;
}
