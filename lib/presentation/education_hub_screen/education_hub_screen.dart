import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/category_filter_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/module_card_widget.dart';
import './widgets/progress_card_widget.dart';
import './widgets/search_bar_widget.dart';
import '../../services/content_service.dart';
import '../../services/current_profile.dart';

class EducationHubScreen extends StatefulWidget {
  const EducationHubScreen({super.key});

  @override
  State<EducationHubScreen> createState() => _EducationHubScreenState();
}

class _EducationHubScreenState extends State<EducationHubScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production state management
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Loaded from the dashboard-managed content (active sessions only).
  List<Map<String, dynamic>> _modules = const [];
  List<String> _categories = const [];
  bool _loading = true;
  String? _error;
  final CurrentProfile _currentProfile = CurrentProfile.instance;

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadContent();
    _currentProfile.addListener(_onProfileChanged);
    _currentProfile.load();
  }

  @override
  void dispose() {
    _currentProfile.removeListener(_onProfileChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    // Show the spinner again only for a retry after an error (initState
    // already starts in the loading state; no setState during initState).
    if (mounted && _modules.isEmpty && !_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final content = await ContentService.instance.loadEducation();
      if (!mounted) return;
      setState(() {
        _modules = content.sessions;
        _categories = content.categories;
        _loading = false;
        _error = null;
        // The selected category may have been hidden or renamed by staff.
        if (_selectedCategory != 'All' &&
            !_categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
      });
    } on ContentException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredModules {
    return _modules.where((m) {
      final matchesCategory =
          _selectedCategory == 'All' || m['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final tags = (m['tags'] as List?)?.cast<String>() ?? const <String>[];
      final matchesSearch =
          q.isEmpty ||
          (m['title'] as String).toLowerCase().contains(q) ||
          (m['description'] as String).toLowerCase().contains(q) ||
          tags.any((t) => t.toLowerCase().contains(q));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _completedCount =>
      _modules.where((m) => m['status'] == 'completed').length;

  Future<void> _onModuleTapped(Map<String, dynamic> module) async {
    await context.push(AppRoutes.lessonDetail, extra: module);
    // Back from a lesson: pick up progress and any changes staff made.
    if (mounted) _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredModules;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _loadContent,
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeAppBarWidget(
                      userName: _currentProfile.profile?.firstName ?? '',
                      initial: _currentProfile.profile?.initial ?? '',
                      onAvatarTap: () => context.go(AppRoutes.profile),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Health\nEducation Hub',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SearchBarInputWidget(
                      controller: _searchController,
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                    const SizedBox(height: 16),
                    ProgressCardWidget(
                      completed: _completedCount,
                      total: _modules.length,
                    ),
                    const SizedBox(height: 20),
                    CategoryFilterWidget(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              )
            else if (_error != null && _modules.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 40,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                  child: Text(
                    _modules.isEmpty
                        ? 'No lessons are available yet. Check back soon.'
                        : 'No lessons match your search.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              )
            else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final module = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ModuleCardWidget(
                      module: module,
                      animationIndex: index,
                      onTap: () => _onModuleTapped(module),
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
