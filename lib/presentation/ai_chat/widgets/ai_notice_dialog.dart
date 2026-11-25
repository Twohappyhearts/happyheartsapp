import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/agent_config.dart';
import '../../../services/app_language.dart';
import '../../../theme/app_theme.dart';
import '../ai_chat_controller.dart';
import '../ai_chat_strings.dart';

/// Shown before a patient first uses the AI assistant, and again when the
/// notice or the Terms of Use changes. It cannot be dismissed: the patient
/// ticks "I understand and agree", then presses Continue.
///
/// It starts with the research team's disclaimer: word for word in English;
/// translated in other languages, with a line saying the English text is the
/// official one. The language picker changes the app's language.
Future<void> showAiNoticeDialog(
  BuildContext context, {
  required AiChatController controller,
  required void Function(Uri uri) onOpenLink,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _AiNoticeDialog(controller: controller, onOpenLink: onOpenLink),
    ),
  );
}

class _AiNoticeDialog extends StatefulWidget {
  final AiChatController controller;
  final void Function(Uri uri) onOpenLink;

  const _AiNoticeDialog({required this.controller, required this.onOpenLink});

  @override
  State<_AiNoticeDialog> createState() => _AiNoticeDialogState();
}

class _AiNoticeDialogState extends State<_AiNoticeDialog> {
  bool _checked = false;
  bool _closed = false;

  /// "Terms of Use" in the disclaimer (translated, and the English original).
  late final TapGestureRecognizer _termsLink = _termsRecognizer();
  late final TapGestureRecognizer _termsLinkEnglish = _termsRecognizer();

  TapGestureRecognizer _termsRecognizer() =>
      TapGestureRecognizer()
        ..onTap = () =>
            widget.onOpenLink(AgentConfig.legalUri(LegalDocument.terms));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    AppLanguageController.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    AppLanguageController.instance.removeListener(_onChanged);
    _termsLink.dispose();
    _termsLinkEnglish.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted || _closed) return;
    // Accepted: close the notice.
    if (!widget.controller.noticeNeeded) {
      _closed = true;
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  TextSpan _disclaimer(
    String before,
    String link,
    String after,
    TextStyle style,
    TapGestureRecognizer recognizer,
  ) {
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: before),
        if (link.isNotEmpty)
          TextSpan(
            text: link,
            recognizer: recognizer,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primary,
            ),
          ),
        TextSpan(text: after),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageController.instance.code;
    final text = AiNoticeStrings.of(lang);
    final english = AiNoticeStrings.of('en');
    final c = widget.controller;
    final body = GoogleFonts.plusJakartaSans(
      fontSize: 14.5,
      height: 1.5,
      color: AppTheme.textMedium,
    );

    return Dialog(
      backgroundColor: AppTheme.surfaceLight,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only the text scrolls; the agree box and Continue stay in view.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        _LanguagePicker(value: lang, label: text.language),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      text.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            _disclaimer(
                              text.disclaimerBefore,
                              text.disclaimerLink,
                              text.disclaimerAfter,
                              body.copyWith(color: AppTheme.textDark),
                              _termsLink,
                            ),
                          ),
                          if (lang != 'en') ...[
                            const SizedBox(height: 8),
                            Text(
                              text.officialNote,
                              style: body.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text.rich(
                                _disclaimer(
                                  english.disclaimerBefore,
                                  english.disclaimerLink,
                                  english.disclaimerAfter,
                                  body.copyWith(
                                    fontSize: 12.5,
                                    color: AppTheme.textLight,
                                  ),
                                  _termsLinkEnglish,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final point in text.points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 9),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(point, style: body)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: AppTheme.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: CheckboxListTile(
                      value: _checked,
                      onChanged: (v) => setState(() => _checked = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppTheme.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        text.agree,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ),
                  if (c.noticeFailed) ...[
                    const SizedBox(height: 10),
                    Text(
                      text.saveError,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: !_checked || c.acceptingNotice
                        ? null
                        : c.acceptNotice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      c.acceptingNotice ? '…' : text.continueLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app's language, by its own name. Changing it changes the whole app.
class _LanguagePicker extends StatelessWidget {
  final String value;
  final String label;
  const _LanguagePicker({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        height: 36,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: aiChatLanguages.contains(value) ? value : 'en',
            isDense: true,
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
            items: [
              for (final l in aiChatLanguages)
                DropdownMenuItem(
                  value: l,
                  child: Text(aiChatLanguageNative[l] ?? l),
                ),
            ],
            onChanged: (l) {
              if (l != null) AppLanguageController.instance.choose(l);
            },
          ),
        ),
      ),
    );
  }
}
