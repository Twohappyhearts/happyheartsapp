import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/current_profile.dart';
import '../../theme/app_theme.dart';
import './widgets/infographic_section_widget.dart';
import './widgets/kahoot_section_widget.dart';
import './widgets/lesson_detail_app_bar_widget.dart';
import './widgets/video_section_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? moduleData;

  const LessonDetailScreen({this.moduleData, super.key});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production state management
  bool _isBookmarked = false;

  late Map<String, dynamic> _module;
  final CurrentProfile _currentProfile = CurrentProfile.instance;

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  static const Map<String, dynamic> _fallbackModule = {
    'id': 'module_3',
    'title': 'Understanding Prenatal Anxiety',
    'category': 'Emotional Support & Resources',
    'description': 'Recognizing and managing anxiety during pregnancy',
    'duration': '35 min',
    'status': 'in_progress',
    'imageUrl':
        'https://img.rocket.new/generatedImages/rocket_gen_img_16ddb4737-1770095453193.png',
    'semanticLabel':
        'Young woman sitting peacefully by window with hands folded in meditation pose',
    'infographicUrl':
        'https://res.cloudinary.com/drytmgv5/image/upload/f_auto,q_auto/peri-anxiModified-11-25-2025-LN-819x1024',
    'videoUrl': 'https://www.youtube.com/watch?v=0xEC23Zmdrs',
    'videoId': '0xEC23Zmdrs',
    'kahootUrl':
        'https://kahoot.it/challenge/03641688?challenge-id=dc7425a3-9036-4c27-8720-c187aa13c03a_1788587319343',
  };

  @override
  void initState() {
    super.initState();
    _module = widget.moduleData ?? _fallbackModule;
    _currentProfile.addListener(_onProfileChanged);
    _currentProfile.load();
  }

  @override
  void dispose() {
    _currentProfile.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            LessonDetailAppBarWidget(
              isBookmarked: _isBookmarked,
              onBack: () => context.pop(),
              onBookmark: () => setState(() => _isBookmarked = !_isBookmarked),
              onShare: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module title + category
                    _buildModuleHeader(),
                    const SizedBox(height: 24),

                    // Section 1: Infographic
                    InfographicSectionWidget(
                      infographicUrl: _module['infographicUrl'] as String,
                      moduleTitle: _module['title'] as String,
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Video
                    VideoSectionWidget(
                      videoId: _module['videoId'] as String,
                      duration: _module['duration'] as String,
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Kahoot
                    KahootSectionWidget(
                      kahootUrl: _module['kahootUrl'] as String,
                      username: _currentProfile.profile?.username ?? '...',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleHeader() {
    final category = _module['category'] as String;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _module['title'] as String,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _module['description'] as String,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AppTheme.textMedium,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _module['duration'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_rounded, size: 13, color: AppTheme.purple),
                  SizedBox(width: 4),
                  Text(
                    '3 sections',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
