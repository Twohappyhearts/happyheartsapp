import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/agent_config.dart';
import '../services/app_language.dart';

/// Opens the Terms of Use or Privacy Policy (a PDF served by the dashboard)
/// in an in-app browser, or the phone's browser if that is not available.
Future<void> openLegalDocument(
  BuildContext context,
  LegalDocument document,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = context.l10n.couldNotOpenLink;
  final uri = AgentConfig.legalUri(document);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {}
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open $uri: $e');
    }
  }
  if (!opened) {
    messenger?.showSnackBar(
      SnackBar(content: Text(failed), behavior: SnackBarBehavior.floating),
    );
  }
}
