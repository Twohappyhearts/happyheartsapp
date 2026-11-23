import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/legal_links.dart';
import '../../services/agent_config.dart';
import '../../services/app_language.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../services/current_profile.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CurrentProfile _current = CurrentProfile.instance;

  @override
  void initState() {
    super.initState();
    _current.addListener(_onProfileChanged);
    _current.load();
  }

  @override
  void dispose() {
    _current.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _editName(UserProfile profile) async {
    // The dialog owns its TextEditingController and disposes it in its own
    // dispose(). Disposing it here, right after showDialog returns, crashed the
    // app: the dialog's closing animation still renders the TextField.
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditNameDialog(initialName: profile.fullName),
    );
    if (!mounted) return;
    if (newName == null || newName.isEmpty || newName == profile.fullName) {
      return;
    }
    try {
      await _current.updateFullName(newName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ProfileException
                ? e.message
                : context.l10n.profileErrorSaveName,
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final email = AuthService.instance.email;
    if (email == null) return;
    try {
      await AuthService.instance.requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileResetSent(email)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.signOut,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        content: Text(
          context.l10n.profileSignOutConfirm,
          style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Real sign-out; the router redirect returns to sign-in.
              await AuthService.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.l10n.signOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = AppLanguageController.instance;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppMenuButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.navProfile,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Avatar + name card (real account data)
                    _ProfileHeaderCard(
                      profile: _current.profile,
                      isLoading: _current.isLoading,
                      error: _current.error,
                      onRetry: () => _current.load(force: true),
                      onEdit: _current.profile == null
                          ? null
                          : () => _editName(_current.profile!),
                    ),
                    const SizedBox(height: 24),

                    // Progress summary
                    const _ProgressSummaryCard(),
                    const SizedBox(height: 24),

                    // Account section
                    _SectionLabel(label: l10n.profileAccount),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.lock_reset_rounded,
                      iconColor: AppTheme.primary,
                      iconBg: AppTheme.primaryContainer,
                      title: l10n.profileChangePassword,
                      onTap: _changePassword,
                    ),
                    const SizedBox(height: 24),

                    // Preferences. (The Push Notifications / Learning
                    // Reminders switches were removed: nothing sends
                    // notifications yet. Add them back with real reminders.)
                    _SectionLabel(label: l10n.profilePreferences),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.language_rounded,
                      iconColor: AppTheme.primary,
                      iconBg: AppTheme.primaryContainer,
                      title: l10n.languageTitle,
                      trailing: language.chosen == null
                          ? l10n.languagePhone
                          : language.language.nativeName,
                      onTap: () => showLanguagePicker(context),
                    ),
                    const SizedBox(height: 24),

                    // About section
                    _SectionLabel(label: l10n.profileAbout),
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF0369A1),
                      iconBg: const Color(0xFFE0F2FE),
                      title: l10n.profileVersion,
                      trailing: '1.0.0',
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF15803D),
                      iconBg: const Color(0xFFDCFCE7),
                      title: l10n.legalPrivacy,
                      onTap: () =>
                          openLegalDocument(context, LegalDocument.privacy),
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3C7),
                      title: l10n.legalTerms,
                      onTap: () =>
                          openLegalDocument(context, LegalDocument.terms),
                    ),
                    const SizedBox(height: 24),

                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppTheme.errorColor,
                        ),
                        label: Text(
                          l10n.signOut,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onEdit;

  const _ProfileHeaderCard({
    required this.profile,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: decoration,
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            : Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error ?? context.l10n.profileNotAvailable,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
      );
    }

    final p = profile!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: decoration,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                p.initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '@${p.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                if (p.phoneDisplay != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.phoneDisplay!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: context.l10n.profileEditName,
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppTheme.textMedium,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Summary Card
// ─────────────────────────────────────────────────────────────────────────────

/// Real totals for the signed-in patient (same numbers as the Progress tab).
class _ProgressSummaryCard extends StatefulWidget {
  const _ProgressSummaryCard();

  @override
  State<_ProgressSummaryCard> createState() => _ProgressSummaryCardState();
}

class _ProgressSummaryCardState extends State<_ProgressSummaryCard> {
  LearningSummary? _summary;
  bool _loading = true;
  bool _failed = false;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Profile is a bottom tab kept alive in an IndexedStack: refresh when it
    // becomes visible again.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_wasVisible && !_loading) _load();
    _wasVisible = visible;
  }

  Future<void> _load() async {
    _loading = true;
    try {
      final s = await ContentService.instance.loadLearningSummary();
      if (!mounted) return;
      setState(() {
        _summary = s;
        _failed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = _summary == null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = _summary;
    String v(String Function(LearningSummary s) f) =>
        summary == null ? '—' : f(summary);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.profileLearningSummary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                value: v((s) => '${s.completed}'),
                label: l10n.statusCompleted,
              ),
              _Divider(),
              _MiniStat(
                value: v((s) => '${s.inProgress}'),
                label: l10n.statusInProgress,
              ),
              _Divider(),
              _MiniStat(
                value: v(
                  (s) => LearningSummary.formatTime(s.timeSpentSec, l10n),
                ),
                label: l10n.statTimeSpent,
              ),
              _Divider(),
              _MiniStat(
                value: v((s) => '${(s.percent * 100).round()}%'),
                label: l10n.profileStatComplete,
              ),
            ],
          ),
          if (_failed) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _load,
              child: Text(
                l10n.profileProgressFailed,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFFBBF7D0));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Tile
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String trailing;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;

  /// Current value shown before the chevron (e.g. the chosen language).
  final String? trailing;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Edit name" dialog. Pops with the trimmed name, or null when cancelled.
class _EditNameDialog extends StatefulWidget {
  final String initialName;

  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(context.l10n.profileEditName),
      content: TextField(
        // Tapping anywhere outside the field closes the keyboard.
        onTapOutside: (_) =>
            FocusManager.instance.primaryFocus?.unfocus(),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        maxLength: 100,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(labelText: context.l10n.fieldFullName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }
}
