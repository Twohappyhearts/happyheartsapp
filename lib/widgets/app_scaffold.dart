import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_menu.dart';
import './app_navigation.dart';
import './password_change_gate.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary-password accounts must set their own password first.
    return PasswordChangeGate(
      child: Scaffold(
        key: appShellScaffoldKey,
        body: navigationShell,
        bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
        // Side menu (☰ at the top-left of each tab): Survey and
        // "I need assistance", which used to be a floating Help button.
        drawer: AppDrawer(shellContext: context),
        // Open it with ☰ only. The left-edge swipe is iOS's "back" gesture, and this
        // scaffold wraps the pages pushed inside each tab (lessons, surveys), so an
        // edge drag here opened the menu on pages that should go back instead.
        drawerEnableOpenDragGesture: false,
      ),
    );
  }
}
