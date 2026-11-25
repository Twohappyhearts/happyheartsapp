import 'package:flutter/material.dart';

import '../presentation/assessments_screen/assessments_screen.dart';
import '../presentation/assistance/assistance_request_sheet.dart';
import '../presentation/assistance/my_assistance_requests_screen.dart';
import '../presentation/inbox/inbox_screen.dart';
import '../presentation/inbox/inbox_strings.dart';
import '../services/app_language.dart';
import '../services/current_profile.dart';
import '../services/inbox_service.dart';
import '../services/survey_service.dart';
import '../theme/app_theme.dart';

/// Key of the main shell's Scaffold (AppScaffold), which owns the side menu.
/// Each tab has its own inner Scaffold, so `Scaffold.of(context)` would find
/// that one instead; the menu button opens the drawer through this key.
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppMenu() => appShellScaffoldKey.currentState?.openDrawer();

/// The ☰ button at the top-left of each tab. Same look as the app's other
/// square header buttons; a small dot when the inbox has unread messages.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.menuOpen,
      child: InkWell(
        onTap: openAppMenu,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.menu_rounded,
                size: 22,
                color: AppTheme.textDark,
              ),
              Positioned(
                top: 7,
                right: 7,
                child: ListenableBuilder(
                  listenable: InboxService.instance,
                  builder: (context, _) => InboxService.instance.unread > 0
                      ? const _UnreadDot()
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side menu: Survey, and "I need assistance" (replaces the floating Help
/// button that used to sit at the bottom-right of every tab).
class AppDrawer extends StatelessWidget {
  /// A context above the drawer (the shell's), used after the drawer closes.
  final BuildContext shellContext;

  const AppDrawer({required this.shellContext, super.key});

  void _closeThen(BuildContext drawerContext, void Function() action) {
    Navigator.of(drawerContext).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Drawer(
      backgroundColor: AppTheme.surfaceLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: InboxService.instance,
              builder: (context, _) {
                final strings = InboxStrings.of(
                  AppLanguageController.instance.code,
                );
                final unread = InboxService.instance.unread;
                return _DrawerItem(
                  icon: Icons.inbox_outlined,
                  iconColor: AppTheme.primary,
                  iconBg: AppTheme.primaryContainer,
                  label: strings.menu,
                  subtitle: unread > 0
                      ? strings.unread(unread)
                      : strings.menuSubtitle,
                  badge: unread,
                  onTap: () => _closeThen(context, () => openInbox(shellContext)),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.assignment_outlined,
              iconColor: AppTheme.purple,
              iconBg: AppTheme.purpleContainer,
              label: l10n.menuAssessments,
              subtitle: l10n.menuAssessmentsSubtitle,
              onTap: () => _closeThen(context, () {
                Navigator.of(shellContext).push(
                  MaterialPageRoute(
                    builder: (_) => const AssessmentsScreen(
                      placement: SurveyPlacement.survey,
                      standalone: true,
                    ),
                  ),
                );
              }),
            ),
            _DrawerItem(
              icon: Icons.support_rounded,
              iconColor: AppTheme.primary,
              iconBg: AppTheme.primaryContainer,
              label: l10n.menuAssistance,
              subtitle: l10n.menuAssistanceSubtitle,
              onTap: () => _closeThen(
                context,
                () => showAssistanceRequestSheet(shellContext),
              ),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              iconColor: AppTheme.textMedium,
              iconBg: AppTheme.surfaceVariantLight,
              label: l10n.menuMyRequests,
              subtitle: l10n.menuMyRequestsSubtitle,
              onTap: () => _closeThen(
                context,
                () => openMyAssistanceRequests(shellContext),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                l10n.menuEmergency,
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CurrentProfile.instance,
      builder: (context, _) {
        final p = CurrentProfile.instance.profile;
        final name = (p?.fullName.trim().isNotEmpty ?? false) ? p!.fullName.trim() : 'HappyHearts';
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (p?.username.isNotEmpty ?? false)
                      Text(
                        '@${p!.username}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  /// Unread count shown before the chevron (0: none).
  final int badge;

  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 21, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

/// Unread inbox marker on the ☰ button.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.surfaceVariantLight, width: 1.5),
      ),
    );
  }
}
