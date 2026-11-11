import 'package:flutter/material.dart';

import '../services/app_language.dart';
import '../services/message_language.dart';
import '../services/message_language_settings.dart';
import '../theme/app_theme.dart';

/// Before a message goes to the research team (Care Team chat, "I need
/// assistance"): if it seems to be in a language the team doesn't read, ask
/// whether to send it anyway. Only a reminder, never a block.
///
/// Returns true to send, false when the patient chose to edit the message.
Future<bool> confirmMessageLanguage(BuildContext context, String text) async {
  final detected = detectMessageLanguage(text);
  if (detected == null) return true; // too short to tell
  final accepted = await MessageLanguageSettings.instance.acceptedLanguages();
  if (isMessageLanguageAccepted(detected, accepted)) return true;
  if (!context.mounted) return true;

  final l10n = context.l10n;
  final names = [
    for (final code in accepted) appLanguageFor(code)?.nativeName ?? code,
  ].join(l10n.listSeparator);
  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(
        Icons.translate_rounded,
        color: AppTheme.warningColor,
        size: 28,
      ),
      title: Text(l10n.msgLangTitle, textAlign: TextAlign.center),
      content: Text(
        l10n.msgLangBody(names),
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppTheme.textMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.msgLangEdit),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.msgLangSendAnyway),
        ),
      ],
    ),
  );
  return send ?? false;
}
