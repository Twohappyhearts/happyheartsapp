import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';

class _TabSpec {
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final IconData selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  static String _navEducation(AppLocalizations l) => l.navEducation;
  static String _navResources(AppLocalizations l) => l.navResources;
  static String _navProgress(AppLocalizations l) => l.navProgress;
  static String _navChat(AppLocalizations l) => l.navChat;
  static String _navProfile(AppLocalizations l) => l.navProfile;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: _navEducation,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      branchIndex: 0,
    ),
    _TabSpec(
      label: _navResources,
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      branchIndex: 1,
    ),
    _TabSpec(
      label: _navProgress,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      branchIndex: 2,
    ),
    _TabSpec(
      label: _navChat,
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      branchIndex: 3,
    ),
    _TabSpec(
      label: _navProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      branchIndex: 4,
    ),
  ];

  void _onTabTapped(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) return;
    setState(() {
      _selectedVisualIndex = visualIndex;
    });
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == widget.navigationShell.currentIndex) {
        if (_selectedVisualIndex != i) {
          setState(() => _selectedVisualIndex = i);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isActive = _selectedVisualIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => _onTabTapped(index),
                  splashColor: AppTheme.primaryContainer,
                  highlightColor: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isActive ? tab.selectedIcon : tab.icon,
                            size: 20,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label(context.l10n),
                          // The bar has a fixed height: labels follow the
                          // phone's text size only up to 120%.
                          textScaler: MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 1.2),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
