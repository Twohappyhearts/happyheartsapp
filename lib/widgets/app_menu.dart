import 'package:flutter/material.dart';

import '../presentation/assessments_screen/assessments_screen.dart';
import '../presentation/assistance/assistance_request_sheet.dart';
import '../presentation/assistance/my_assistance_requests_screen.dart';
import '../services/current_profile.dart';
import '../services/survey_service.dart';
import '../theme/app_theme.dart';

/// Key of the main shell's Scaffold (AppScaffold), which owns the side menu.
/// Each tab has its own inner Scaffold, so `Scaffold.of(context)` would find
/// that one instead; the menu button opens the drawer through this key.
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppMenu() => appShellScaffoldKey.currentState?.openDrawer();

/// The ☰ button at the top-left of each tab. Same look as the app's other
/// square header buttons.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open menu',
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
          child: const Icon(
            Icons.menu_rounded,
            size: 22,
            color: AppTheme.textDark,
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
    return Drawer(
      backgroundColor: AppTheme.surfaceLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.assignment_outlined,
              iconColor: AppTheme.purple,
              iconBg: AppTheme.purpleContainer,
              label: 'Holistic Assessments',
              subtitle: 'Questionnaires from your care team',
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
              label: 'I need assistance',
              subtitle: 'Ask your care team for help',
              onTap: () => _closeThen(
                context,
                () => showAssistanceRequestSheet(shellContext),
              ),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              iconColor: AppTheme.textMedium,
              iconBg: AppTheme.surfaceVariantLight,
              label: 'My help requests',
              subtitle: 'See the status of what you sent',
              onTap: () => _closeThen(
                context,
                () => openMyAssistanceRequests(shellContext),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'In an emergency, call 911.',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
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

  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
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
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
