import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/category_filter_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/module_card_widget.dart';
import './widgets/progress_card_widget.dart';
import './widgets/search_bar_widget.dart';
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

  static final List<Map<String, dynamic>> _moduleMaps = [
    {
      'id': 'module_1',
      'title': 'Preeclampsia Education',
      'category': 'Heart Health',
      'description':
          'Understanding preeclampsia risks, signs, and management during pregnancy',
      'duration': '30 min',
      'status': 'completed',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_41f31f362-1791350628906.png',
      'semanticLabel':
          'Preeclampsia education infographic showing risks, signs, and management during pregnancy',
      'infographicUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_49143873a-1792368870940.png',
      'videoUrl': 'https://www.youtube.com/watch?v=Y05BNvwf9w0',
      'videoId': 'Y05BNvwf9w0',
      'kahootUrl':
          'https://kahoot.it/challenge/05183456?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1787846922340',
    },
    {
      'id': 'module_2',
      'title': 'Physical Activity and Sleep',
      'category': 'Sleep Health',
      'description':
          'Building healthy sleep and exercise habits during pregnancy',
      'duration': '25 min',
      'status': 'completed',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_11e27b303-1767093625473.png',
      'semanticLabel':
          'Physical activity and sleep infographic showing healthy exercise and sleep habits during pregnancy',
      'infographicUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_11e27b303-1767093625473.png',
      'videoUrl': 'https://www.youtube.com/watch?v=s4LWkyhV9AQ',
      'videoId': 's4LWkyhV9AQ',
      'kahootUrl':
          'https://kahoot.it/challenge/04339948?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788603912485',
    },
    {
      'id': 'module_3',
      'title': 'Understanding Prenatal Anxiety',
      'category': 'Emotional Support & Resources',
      'description': 'Recognizing and managing anxiety during pregnancy',
      'duration': '35 min',
      'status': 'in_progress',
      'imageUrl':
          'https://res.cloudinary.com/drytmgv5/image/upload/f_auto,q_auto/peri-anxiModified-11-25-2025-LN-819x1024',
      'semanticLabel':
          'Prenatal anxiety infographic showing how to recognize and manage anxiety during pregnancy',
      'infographicUrl':
          'https://res.cloudinary.com/drytmgv5/image/upload/f_auto,q_auto/peri-anxiModified-11-25-2025-LN-819x1024',
      'videoUrl': 'https://www.youtube.com/watch?v=0xEC23Zmdrs',
      'videoId': '0xEC23Zmdrs',
      'kahootUrl':
          'https://kahoot.it/challenge/03641688?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788587319343',
    },
    {
      'id': 'module_4',
      'title': 'Perinatal Depression & Anxiety Resources',
      'category': 'Emotional Support & Resources',
      'description': 'Resources and support for perinatal mood disorders',
      'duration': '30 min',
      'status': 'available',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_4ea9ae0e5-1791350627795.png',
      'semanticLabel':
          'Perinatal depression and anxiety resources infographic showing support options for mood disorders',
      'infographicUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_4a2a636d1-1792368870652.png',
      'videoUrl': 'https://www.youtube.com/watch?v=Kq_Jm_PJuqo',
      'videoId': 'Kq_Jm_PJuqo',
      'kahootUrl':
          'https://kahoot.it/challenge/07018409?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788596476612',
    },
    {
      'id': 'module_5',
      'title': 'How to Talk to Your Healthcare Provider',
      'category': 'Resources',
      'description': 'Tips for effective communication with your medical team',
      'duration': '20 min',
      'status': 'available',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_4c29facf2-1791350628334.png',
      'semanticLabel':
          'Communicating with healthcare provider infographic showing tips for effective medical communication',
      'infographicUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_482332aaf-1792368871006.png',
      'videoUrl': 'https://www.youtube.com/watch?v=lJnPvsTvsyU',
      'videoId': 'lJnPvsTvsyU',
      'kahootUrl':
          'https://kahoot.it/challenge/04107757?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788598632783',
    },
  ];

  late List<Map<String, dynamic>> _modules;
  final CurrentProfile _currentProfile = CurrentProfile.instance;

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _modules = List<Map<String, dynamic>>.from(_moduleMaps);
    _currentProfile.addListener(_onProfileChanged);
    _currentProfile.load();
  }

  @override
  void dispose() {
    _currentProfile.removeListener(_onProfileChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredModules {
    return _modules.where((m) {
      final matchesCategory =
          _selectedCategory == 'All' || m['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (m['title'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (m['description'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _completedCount =>
      _modules.where((m) => m['status'] == 'completed').length;

  void _onModuleTapped(Map<String, dynamic> module) {
    context.push(AppRoutes.lessonDetail, extra: module);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredModules;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeAppBarWidget(
                      userName: _currentProfile.profile?.firstName ?? '',
                      hasNotifications: true,
                      onNotificationTap: () {},
                      onAvatarTap: () {},
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
                    ProgressCardWidget(completed: _completedCount, total: 5),
                    const SizedBox(height: 20),
                    CategoryFilterWidget(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
    );
  }
}
