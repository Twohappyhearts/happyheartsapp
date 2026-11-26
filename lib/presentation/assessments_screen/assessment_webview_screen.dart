import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/app_language.dart';
import '../../services/survey_service.dart';
import '../../theme/app_theme.dart';

class AssessmentWebViewScreen extends StatefulWidget {
  /// survey_links.id: what a completion is recorded for.
  final String surveyId;
  final String title;
  final String url;

  const AssessmentWebViewScreen({
    required this.surveyId,
    required this.title,
    required this.url,
    super.key,
  });

  @override
  State<AssessmentWebViewScreen> createState() =>
      _AssessmentWebViewScreenState();
}

/// Pops with `true` when the survey reported completion.
class _AssessmentWebViewScreenState extends State<AssessmentWebViewScreen> {
  late final WebViewController _controller;
  late final String _surveyHost = Uri.parse(widget.url).host.toLowerCase();
  bool _isLoading = true;
  bool _hasError = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Images/scripts failing must not hide a working survey page.
            if (error.isForMainFrame == false || !mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Keeps the survey inside the web view, but:
  ///  * the REDCap "survey finished" redirect is recorded, not loaded;
  ///  * phone / text / email links (e.g. "Call 988", "Text 741741") open the
  ///    phone's dialer / messages / mail app;
  ///  * links to other websites (resource pages) open in the browser, so the
  ///    patient doesn't lose the survey.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;
    if (SurveyService.isCompletionUrl(url)) {
      _onSurveyCompleted();
      return NavigationDecision.prevent;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return NavigationDecision.prevent;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'tel' || scheme == 'sms' || scheme == 'mailto') {
      launchUrl(uri);
      return NavigationDecision.prevent;
    }
    if (scheme == 'http' || scheme == 'https') {
      if (!request.isMainFrame || uri.host.toLowerCase() == _surveyHost) {
        return NavigationDecision.navigate;
      }
      launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    if (scheme == 'about' || scheme == 'data' || scheme == 'blob') {
      return NavigationDecision.navigate;
    }
    return NavigationDecision.prevent; // unknown app schemes
  }

  Future<void> _onSurveyCompleted() async {
    if (_completed) return;
    setState(() {
      _completed = true;
      _isLoading = false;
    });
    try {
      await SurveyService.instance.recordCompletion(widget.surveyId);
    } catch (_) {
      // The answers are already saved in REDCap; only our record failed.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.surveyRecordFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildCompleted() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.surveyThanks,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.surveyThanksBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: context.l10n.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppTheme.textDark,
          ),
          onPressed: () => Navigator.of(context).pop(_completed),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _completed
          ? _buildCompleted()
          : Stack(
              children: [
                if (!_hasError) WebViewWidget(controller: _controller),
                if (_isLoading && !_hasError)
                  Container(
                    color: AppTheme.backgroundLight,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.surveyLoading,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_hasError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 56,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.surveyLoadFailedTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.surveyLoadFailedBody,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _hasError = false;
                              });
                              _controller.reload();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(context.l10n.retry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
