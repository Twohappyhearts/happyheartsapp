import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_menu.dart';
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
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
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
          content: Text(e.toString()),
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
          content: Text('Password reset link sent to $email'),
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
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMedium),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        const Expanded(
                          child: Text(
                            'Profile',
                            style: TextStyle(
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
                    _SectionLabel(label: 'Account'),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.lock_reset_rounded,
                      iconColor: AppTheme.primary,
                      iconBg: AppTheme.primaryContainer,
                      title: 'Change password (send reset email)',
                      onTap: _changePassword,
                    ),
                    const SizedBox(height: 24),

                    // Settings section
                    _SectionLabel(label: 'Preferences'),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.notifications_rounded,
                      iconColor: AppTheme.primary,
                      iconBg: AppTheme.primaryContainer,
                      title: 'Push Notifications',
                      subtitle: 'Receive updates and reminders',
                      value: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                    const SizedBox(height: 8),
                    _ToggleTile(
                      icon: Icons.alarm_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFEDE9FE),
                      title: 'Learning Reminders',
                      subtitle: 'Daily nudges to continue your modules',
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                    const SizedBox(height: 24),

                    // About section
                    _SectionLabel(label: 'About'),
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF0369A1),
                      iconBg: const Color(0xFFE0F2FE),
                      title: 'App Version',
                      trailing: '1.0.0',
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF15803D),
                      iconBg: const Color(0xFFDCFCE7),
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'Terms of Service',
                      onTap: () {},
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
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
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
                      error ?? 'Your profile is not available.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
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
              tooltip: 'Edit name',
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
              const Text(
                'Learning Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(value: v((s) => '${s.completed}'), label: 'Completed'),
              _Divider(),
              _MiniStat(
                value: v((s) => '${s.inProgress}'),
                label: 'In Progress',
              ),
              _Divider(),
              _MiniStat(
                value: v((s) => LearningSummary.formatTime(s.timeSpentSec)),
                label: 'Time Spent',
              ),
              _Divider(),
              _MiniStat(
                value: v((s) => '${(s.percent * 100).round()}%'),
                label: 'Complete',
              ),
            ],
          ),
          if (_failed) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _load,
              child: const Text(
                'Could not load your progress. Tap to retry.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMedium),
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
// Toggle Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primary,
            ),
          ],
        ),
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
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
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
      title: const Text('Edit name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        maxLength: 100,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(labelText: 'Full name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
