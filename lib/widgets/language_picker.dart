import 'package:flutter/material.dart';

import '../services/app_language.dart';
import '../theme/app_theme.dart';

/// Bottom sheet with "Phone language" and the app's 8 languages, each written
/// in its own script so a patient can find theirs without reading English.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final controller = AppLanguageController.instance;
    final l10n = context.l10n;
    final chosen = controller.chosen;
    final phone = appLanguageFor(controller.phoneLanguage)?.nativeName ?? '';

    void pick(String? code) {
      Navigator.of(context).pop();
      controller.choose(code);
    }

    Widget option({
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
      TextDirection? direction,
    }) {
      return ListTile(
        onTap: onTap,
        selected: selected,
        selectedColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Text(
          title,
          textDirection: direction,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppTheme.primary)
            : null,
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l10n.languagePickerTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          option(
            title: l10n.languagePhone,
            subtitle: l10n.languagePhoneDetail(phone),
            selected: chosen == null,
            onTap: () => pick(null),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          for (final language in appLanguages)
            option(
              title: language.nativeName,
              selected: chosen == language.code,
              direction: language.rtl ? TextDirection.rtl : TextDirection.ltr,
              onTap: () => pick(language.code),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Compact "🌐 English" button (sign-in screen, top end corner).
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AppLanguageController.instance.language.nativeName;
    return Semantics(
      button: true,
      label: context.l10n.languageButtonSemantic(name),
      excludeSemantics: true,
      child: TextButton.icon(
        onPressed: () => showLanguagePicker(context),
        icon: const Icon(Icons.language_rounded, size: 20),
        label: Text(name, style: const TextStyle(fontSize: 14)),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.textMedium,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
