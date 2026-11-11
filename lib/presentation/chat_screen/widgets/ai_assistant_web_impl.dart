// Web build placeholder: the Botpress assistant is embedded via WebView on
// iOS / Android only.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/app_language.dart';
import '../../../theme/app_theme.dart';

Widget buildAiAssistantView({
  required String userId,
  required String language,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        appL10n.aiWebOnly,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppTheme.textMedium,
        ),
      ),
    ),
  );
}
