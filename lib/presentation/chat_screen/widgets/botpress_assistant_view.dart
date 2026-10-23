// LEGACY — not used. The previous AI assistant tab (Botpress Webchat in a
// WebView), kept so it can be restored. Replaced by our own agent
// (ai_assistant_web_stub.dart → /m/assistant). Entry point renamed from
// buildAiAssistantView to buildBotpressAssistantView.
//
// Mobile (iOS / Android) implementation of the Botpress AI assistant.
// Loads the official Botpress Webchat inside a WebView, as recommended by
// Botpress for native apps (https://botpress.com/docs/webchat/integrations/react-native/).
//
// Identity: each HappyHearts account's Botpress identity (user id, user key,
// conversation id) is kept in public.ai_identities. Before the webchat starts,
// the page wipes any Botpress data left on the device and restores this
// account's identity, so accounts never see each other's AI conversation and
// an account gets its own history back on any device.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/ai_identity_service.dart';
import '../../../services/botpress_config.dart';
import '../../../theme/app_theme.dart';

Widget buildBotpressAssistantView({required String userId}) =>
    _AiAssistantWebView(key: ValueKey('bp-$userId'), userId: userId);

enum _Phase { loading, ready, failed }

class _AiAssistantWebView extends StatefulWidget {
  final String userId;
  const _AiAssistantWebView({super.key, required this.userId});

  @override
  State<_AiAssistantWebView> createState() => _AiAssistantWebViewState();
}

class _AiAssistantWebViewState extends State<_AiAssistantWebView> {
  WebViewController? _controller;
  _Phase _phase = _Phase.loading;
  String? _failure;
  Timer? _timeout;

  /// Identity currently saved in Supabase for this account (null = none yet).
  AiIdentity? _saved;
  Future<void> _saveChain = Future.value();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _timeout?.cancel();
    if (_phase != _Phase.loading) {
      // Retry after a failure (initState starts in the loading phase already).
      setState(() {
        _phase = _Phase.loading;
        _failure = null;
        _controller = null;
      });
    }
    if (!BotpressConfig.isConfigured) {
      _fail('The AI assistant is not configured.');
      return;
    }

    // Load this account's saved identity first. If that fails we stop, rather
    // than starting a fresh Botpress identity that would replace the saved one.
    AiIdentity? saved;
    try {
      saved = await AiIdentityService.instance.fetchMine();
    } on AiIdentityException catch (e) {
      _fail(e.message);
      return;
    }
    if (!mounted) return;
    _saved = saved;

    final controller = WebViewController();
    try {
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.white);
      await controller.addJavaScriptChannel(
        'BotpressBridge',
        onMessageReceived: (m) => _onBridgeMessage(m.message),
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              _fail('Could not load the AI assistant. Check your connection.');
            }
          },
        ),
      );
      await controller.loadHtmlString(
        _buildHtml(
          injectUrl: BotpressConfig.injectUrl,
          configUrl: BotpressConfig.configUrl,
          storageKey: BotpressConfig.storageKey,
          restore: saved,
        ),
        baseUrl: BotpressConfig.baseUrl,
      );
    } catch (_) {
      _fail('Could not start the AI assistant.');
      return;
    }

    if (!mounted) return;
    setState(() => _controller = controller);
    _timeout = Timer(const Duration(seconds: 20), () {
      if (_phase == _Phase.loading) {
        _fail('The AI assistant is taking too long to respond.');
      }
    });
  }

  void _onBridgeMessage(String raw) {
    Map<dynamic, dynamic>? msg;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) msg = decoded;
    } catch (_) {
      return;
    }
    if (msg == null) return;
    switch (msg['event']) {
      case 'ready':
      case 'opened':
        _timeout?.cancel();
        if (mounted && _phase != _Phase.ready) {
          setState(() => _phase = _Phase.ready);
        }
        break;
      case 'identity':
        final identity = AiIdentity.fromWebchatState(msg['data']);
        if (identity != null) _persist(identity);
        break;
      case 'load_failed':
        _fail('Could not load the AI assistant. Check your connection.');
        break;
      case 'timeout':
        _fail('The AI assistant did not start.');
        break;
    }
  }

  /// Saves the identity the webchat is actually using (new account, new
  /// conversation, or a replaced Botpress user). Saves run one at a time.
  void _persist(AiIdentity identity) {
    _saveChain = _saveChain.then((_) async {
      if (identity.sameAs(_saved)) return;
      try {
        await AiIdentityService.instance.saveMine(identity);
        _saved = identity;
      } catch (_) {
        // Not fatal: the chat still works; we try again on the next report.
      }
    });
  }

  /// Keep the chat in the WebView; open any other link (e.g. a resource the
  /// bot shares) in the phone's browser instead of navigating away.
  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (!request.isMainFrame ||
        uri.scheme == 'about' ||
        uri.scheme == 'data' ||
        uri.scheme == 'blob' ||
        BotpressConfig.allowedHosts.contains(uri.host)) {
      return NavigationDecision.navigate;
    }
    if (uri.scheme == 'https' ||
        uri.scheme == 'http' ||
        uri.scheme == 'tel' ||
        uri.scheme == 'mailto' ||
        uri.scheme == 'sms') {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
    return NavigationDecision.prevent;
  }

  void _fail(String message) {
    _timeout?.cancel();
    if (!mounted || _phase == _Phase.failed) return;
    setState(() {
      _phase = _Phase.failed;
      _failure = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      children: [
        const _AiDisclaimer(),
        Expanded(
          child: Stack(
            children: [
              if (controller != null && _phase != _Phase.failed)
                WebViewWidget(controller: controller),
              if (_phase == _Phase.loading)
                Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                ),
              if (_phase == _Phase.failed)
                Container(
                  color: AppTheme.backgroundLight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_toy_outlined,
                        color: AppTheme.textLight,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _failure ?? 'Something went wrong.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _start,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiDisclaimer extends StatelessWidget {
  const _AiDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.warningColor.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Automated AI assistant — not your care team, and it can make '
              'mistakes. In an emergency, call 911. For questions about your '
              'care, message the Care Team.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.35,
                color: AppTheme.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// JSON that is safe to place inside an inline <script> (no "</script>").
String _jsLiteral(Object? value) =>
    jsonEncode(value).replaceAll('<', r'<').replaceAll('>', r'>');

String _buildHtml({
  required String injectUrl,
  required String configUrl,
  required String storageKey,
  required AiIdentity? restore,
}) {
  const attr = HtmlEscape(HtmlEscapeMode.attribute);
  final inject = attr.convert(injectUrl);
  final config = attr.convert(configUrl);
  final keyJs = _jsLiteral(storageKey);
  final restoreJs = _jsLiteral(restore?.toWebchatState());
  return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #ffffff; overflow: hidden; }
    /* Embedded, full-screen webchat (Botpress "Embedding Webchat" guide). */
    .bpWebchat {
      position: absolute !important; top: 0 !important; left: 0 !important;
      right: 0 !important; bottom: 0 !important;
      width: 100% !important; height: 100% !important;
      max-height: none !important; border-radius: 0 !important;
    }
    .bpFab { display: none !important; }
  </style>
  <script>
    function bpPost(event, data) {
      try { BotpressBridge.postMessage(JSON.stringify({ event: event, data: data || null })); } catch (_) {}
    }
    var BP_KEY = $keyJs;
    // Must run before inject.js: start from a clean slate, then restore this
    // account's own identity (if it has one).
    (function () {
      try {
        [localStorage, sessionStorage].forEach(function (store) {
          Object.keys(store).forEach(function (k) {
            if (k.indexOf('bp-webchat-') === 0) store.removeItem(k);
          });
        });
        var restore = $restoreJs;
        if (restore) localStorage.setItem(BP_KEY, JSON.stringify({ state: restore, version: 0 }));
      } catch (_) {}
    })();
    function bpReportIdentity() {
      try {
        var raw = localStorage.getItem(BP_KEY);
        if (!raw) {
          // Fall back to any webchat client entry (e.g. if the client id changed).
          var k = Object.keys(localStorage).filter(function (x) {
            return x.indexOf('bp-webchat-') === 0 && x.slice(-7) === '-client';
          })[0];
          raw = k ? localStorage.getItem(k) : null;
        }
        if (!raw) return;
        var parsed = JSON.parse(raw);
        if (parsed && parsed.state) bpPost('identity', parsed.state);
      } catch (_) {}
    }
  </script>
</head>
<body>
  <script src="$inject" onerror="bpPost('load_failed', 'inject')"></script>
  <script>
    (function () {
      var started = Date.now();
      function hook() {
        var bp = window.botpress;
        if (!bp || typeof bp.on !== 'function') {
          if (Date.now() - started < 15000) return setTimeout(hook, 100);
          return bpPost('timeout');
        }
        bp.on('webchat:initialized', function () { bpPost('initialized'); bp.open(); });
        bp.on('webchat:ready', function () {
          bpPost('ready');
          bp.open();
          setTimeout(bpReportIdentity, 500);
        });
        bp.on('webchat:opened', function () { bpPost('opened'); });
        // A new conversation was started (first use, or "restart").
        bp.on('conversation', function () { setTimeout(bpReportIdentity, 500); });
        // Embedded mode: there is nothing behind the chat, so never stay closed.
        bp.on('webchat:closed', function () { setTimeout(function () { bp.open(); }, 50); });
        bp.on('error', function (e) { bpPost('error', String((e && e.message) || e)); });
      }
      hook();
    })();
  </script>
  <script src="$config" defer onerror="bpPost('load_failed', 'config')"></script>
</body>
</html>''';
}
