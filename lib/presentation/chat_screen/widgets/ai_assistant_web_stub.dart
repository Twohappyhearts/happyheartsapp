// Mobile (iOS / Android) implementation of the AI assistant tab.
//
// Shows the HappyHearts assistant page (/m/assistant on the dashboard app) in
// a WebView. The page talks to our own AI agent; this widget only:
//   - hands the page the patient's Supabase access token (and fresh ones when
//     Supabase refreshes the session) through `window.HappyHeartsAgent.setToken`;
//   - opens the page in the app's language (?lang=..., reloaded when the
//     patient switches language);
//   - hands links from answers to the phone: web pages to the browser,
//     tel: to the dialer (e.g. 911 / 988), mailto: / sms: to those apps;
//   - shows the usual "Request sent" confirmation when the patient approved a
//     message to the care team inside the chat.
//
// Bridge messages from the page (channel `AgentBridge`): ready, token_expired,
// open_url (data: the absolute link as a string, e.g. "tel:911"; an object
// {url} is accepted too), assistance_sent.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../services/agent_config.dart';
import '../../../services/app_language.dart';
import '../../../theme/app_theme.dart';
import '../../assistance/my_assistance_requests_screen.dart';

/// [language]: app language code. A new value creates a new page (reload).
Widget buildAiAssistantView({
  required String userId,
  required String language,
}) => _AiAssistantWebView(
  key: ValueKey('agent-$userId-$language'),
  userId: userId,
  language: language,
);

/// Schemes the assistant may hand to the phone. Anything else is ignored.
bool isExternalScheme(String scheme) => const {
  'https',
  'http',
  'tel',
  'mailto',
  'sms',
}.contains(scheme.toLowerCase());

/// The link in an `open_url` bridge message: `data` is the absolute link as a
/// string ("https://…", "tel:911", "mailto:…"); an object `{url: …}` is
/// accepted too. Null when missing or not an allowed scheme.
Uri? openUrlLink(Object? data) {
  final raw = data is Map ? data['url'] : data;
  if (raw is! String) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasScheme || !isExternalScheme(uri.scheme)) {
    return null;
  }
  return uri;
}

enum _Phase { loading, ready, failed }

class _AiAssistantWebView extends StatefulWidget {
  final String userId;
  final String language;
  const _AiAssistantWebView({
    super.key,
    required this.userId,
    required this.language,
  });

  @override
  State<_AiAssistantWebView> createState() => _AiAssistantWebViewState();
}

class _AiAssistantWebViewState extends State<_AiAssistantWebView> {
  WebViewController? _controller;
  _Phase _phase = _Phase.loading;
  String? _failure;
  Timer? _timeout;
  StreamSubscription<AuthState>? _authSub;
  bool _pageReady = false;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  void initState() {
    super.initState();
    // Keep the page's token current: Supabase refreshes it about hourly.
    _authSub = _auth.onAuthStateChange.listen(
      (data) {
        if (!_pageReady) return;
        switch (data.event) {
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.signedIn:
            _pushToken(data.session?.accessToken);
            break;
          case AuthChangeEvent.signedOut:
            _pushToken(null);
            break;
          default:
            break;
        }
      },
      onError: (_) {
        // Auth errors (e.g. an expired refresh token) are handled by the app's
        // sign-in flow; the page asks again after its next 401.
      },
    );
    _start();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _timeout?.cancel();
    _pageReady = false;
    if (_phase != _Phase.loading) {
      setState(() {
        _phase = _Phase.loading;
        _failure = null;
        _controller = null;
      });
    }

    final controller = WebViewController();
    try {
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(AppTheme.backgroundLight);
      // The page has its own scrolling message list; without this, iOS bounced the
      // whole page when a swipe reached it.
      await controller.setOverScrollMode(WebViewOverScrollMode.never);
      await controller.addJavaScriptChannel(
        'AgentBridge',
        onMessageReceived: (m) => _onBridgeMessage(m.message),
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              _fail(appL10n.aiErrorConnection);
            }
          },
          onHttpError: (error) {
            final code = error.response?.statusCode ?? 0;
            if (code >= 500 &&
                error.request?.uri.path == AgentConfig.pageUri.path) {
              _fail(appL10n.aiErrorUnavailable);
            }
          },
        ),
      );
      await controller.loadRequest(AgentConfig.pageUriFor(widget.language));
    } catch (_) {
      _fail(appL10n.aiErrorStart);
      return;
    }

    if (!mounted) return;
    setState(() => _controller = controller);
    _timeout = Timer(const Duration(seconds: 25), () {
      if (_phase == _Phase.loading) {
        _fail(appL10n.aiErrorTimeout);
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
        _pageReady = true;
        _timeout?.cancel();
        unawaited(_sendCurrentToken());
        if (mounted && _phase != _Phase.ready) {
          setState(() => _phase = _Phase.ready);
        }
        break;
      case 'token_expired':
        unawaited(_sendCurrentToken(forceRefresh: true));
        break;
      case 'open_url':
        final link = openUrlLink(msg['data']);
        if (link != null) unawaited(_openExternally(link));
        break;
      case 'assistance_sent':
        _showSentConfirmation();
        break;
    }
  }

  /// Gives the page a valid access token, refreshing the session if needed.
  Future<void> _sendCurrentToken({bool forceRefresh = false}) async {
    var session = _auth.currentSession;
    if (session != null && (forceRefresh || session.isExpired)) {
      try {
        session = (await _auth.refreshSession()).session ?? session;
      } catch (_) {
        // Keep the old one; the page asks again after the next 401.
      }
    }
    _pushToken(session?.accessToken);
  }

  void _pushToken(String? token) {
    final controller = _controller;
    if (controller == null || !mounted) return;
    // jsonEncode makes the token a safe JS string literal.
    unawaited(
      controller
          .runJavaScript(
            'window.HappyHeartsAgent && window.HappyHeartsAgent.setToken(${jsonEncode(token)});',
          )
          .catchError((_) {}),
    );
  }

  void _showSentConfirmation() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textDark,
        content: Text(context.l10n.requestSent),
        action: SnackBarAction(
          label: context.l10n.view,
          textColor: AppTheme.primaryContainer,
          onPressed: () {
            if (mounted) openMyAssistanceRequests(context);
          },
        ),
      ),
    );
  }

  /// Hands [uri] to the phone (browser, dialer, mail or messages app).
  static Future<void> _openExternally(Uri uri) async {
    if (!isExternalScheme(uri.scheme)) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AI assistant: could not open a ${uri.scheme} link: $e');
    }
  }

  /// Stay on the assistant page; open anything else in the phone's browser.
  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (!request.isMainFrame ||
        uri.scheme == 'about' ||
        uri.scheme == 'data' ||
        uri.scheme == 'blob' ||
        uri.host == AgentConfig.host) {
      return NavigationDecision.navigate;
    }
    unawaited(_openExternally(uri));
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
        Expanded(
          child: Stack(
            children: [
              if (controller != null && _phase != _Phase.failed)
                WebViewWidget(controller: controller),
              if (_phase == _Phase.loading)
                Container(
                  color: AppTheme.backgroundLight,
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
                        _failure ?? context.l10n.errorGeneric,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _start,
                        child: Text(context.l10n.retry),
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
