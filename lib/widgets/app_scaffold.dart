import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/assistance/assistance_request_sheet.dart';
import '../theme/app_theme.dart';
import './app_navigation.dart';
import './password_change_gate.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({required this.navigationShell, super.key});

  /// Branch index of the Chat tab, which has its own assistance entry point.
  static const int _chatBranch = 4;

  @override
  Widget build(BuildContext context) {
    final showHelp = navigationShell.currentIndex != _chatBranch;
    // Temporary-password accounts must set their own password first.
    return PasswordChangeGate(
      child: Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
      // "I need assistance" is reachable from every tab in one tap.
      floatingActionButton: showHelp
          ? FloatingActionButton.extended(
              heroTag: 'assistance-fab',
              tooltip: 'I need assistance',
              onPressed: () => showAssistanceRequestSheet(context),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.support_rounded),
              label: const Text('Help'),
            )
          : null,
      ),
    );
  }
}
