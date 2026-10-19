import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static final List<Map<String, dynamic>> _modules = [
    {
      'id': 'module_1',
      'title': 'Preeclampsia Education',
      'category': 'Heart Health',
      'duration': '30 min',
      'status': 'completed',
      'icon': Icons.favorite_rounded,
      'iconColor': Color(0xFFDB2777),
      'iconBg': Color(0xFFFCE7F3),
    },
    {
      'id': 'module_2',
      'title': 'Physical Activity and Sleep',
      'category': 'Sleep Health',
      'duration': '25 min',
      'status': 'completed',
      'icon': Icons.bedtime_rounded,
      'iconColor': Color(0xFF7C3AED),
      'iconBg': Color(0xFFEDE9FE),
    },
    {
      'id': 'module_3',
      'title': 'Understanding Prenatal Anxiety',
      'category': 'Emotional Support',
      'duration': '35 min',
      'status': 'in_progress',
      'icon': Icons.psychology_rounded,
      'iconColor': Color(0xFF0369A1),
      'iconBg': Color(0xFFE0F2FE),
    },
    {
      'id': 'module_4',
      'title': 'Perinatal Depression & Anxiety Resources',
      'category': 'Emotional Support',
      'duration': '30 min',
      'status': 'available',
      'icon': Icons.self_improvement_rounded,
      'iconColor': Color(0xFF15803D),
      'iconBg': Color(0xFFDCFCE7),
    },
    {
      'id': 'module_5',
      'title': 'How to Talk to Your Healthcare Provider',
      'category': 'Resources',
      'duration': '20 min',
      'status': 'available',
      'icon': Icons.medical_information_rounded,
      'iconColor': Color(0xFFF59E0B),
      'iconBg': Color(0xFFFEF3C7),
    },
  ];

  int get _completedCount =>
      _modules.where((m) => m['status'] == 'completed').length;

  int get _inProgressCount =>
      _modules.where((m) => m['status'] == 'in_progress').length;

  double get _progressPercent => _completedCount / _modules.length;

  int get _totalMinutes =>
      _modules.where((m) => m['status'] == 'completed').fold(0, (sum, m) {
        final dur = (m['duration'] as String).replaceAll(' min', '');
        return sum + (int.tryParse(dur) ?? 0);
      });

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
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track your learning journey and celebrate milestones.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Overall progress card
                    _OverallProgressCard(
                      completedCount: _completedCount,
                      totalCount: _modules.length,
                      progressPercent: _progressPercent,
                      totalMinutes: _totalMinutes,
                      inProgressCount: _inProgressCount,
                    ),
                    const SizedBox(height: 24),

                    // Stats row
                    _StatsRow(
                      completedCount: _completedCount,
                      totalMinutes: _totalMinutes,
                      inProgressCount: _inProgressCount,
                    ),
                    const SizedBox(height: 28),

                    // Module list header
                    const Text(
                      'Module Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // Module list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final module = _modules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ModuleProgressTile(module: module, index: index),
                  );
                }, childCount: _modules.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overall Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _OverallProgressCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double progressPercent;
  final int totalMinutes;
  final int inProgressCount;

  const _OverallProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.progressPercent,
    required this.totalMinutes,
    required this.inProgressCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Completion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount of $totalCount modules',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(progressPercent * 100).round()}%',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressPercent >= 1.0
                ? '🎉 All modules complete!'
                : inProgressCount > 0
                ? 'Keep going — you\'re making great progress!'
                : 'Start your first module to begin.',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 10,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int completedCount;
  final int totalMinutes;
  final int inProgressCount;

  const _StatsRow({
    required this.completedCount,
    required this.totalMinutes,
    required this.inProgressCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            iconColor: AppTheme.secondary,
            iconBg: AppTheme.secondaryContainer,
            value: '$completedCount',
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.timer_rounded,
            iconColor: AppTheme.primary,
            iconBg: AppTheme.primaryContainer,
            value: '${totalMinutes}m',
            label: 'Time Spent',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.play_circle_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            value: '$inProgressCount',
            label: 'In Progress',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
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
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module Progress Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleProgressTile extends StatelessWidget {
  final Map<String, dynamic> module;
  final int index;

  const _ModuleProgressTile({required this.module, required this.index});

  @override
  Widget build(BuildContext context) {
    final status = module['status'] as String;
    final isCompleted = status == 'completed';
    final isInProgress = status == 'in_progress';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = AppTheme.secondary;
      statusBg = AppTheme.secondaryContainer;
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      statusColor = AppTheme.primary;
      statusBg = AppTheme.primaryContainer;
      statusLabel = 'In Progress';
      statusIcon = Icons.play_circle_rounded;
    } else {
      statusColor = AppTheme.textLight;
      statusBg = AppTheme.surfaceVariantLight;
      statusLabel = 'Not Started';
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppTheme.secondaryContainer
              : isInProgress
              ? AppTheme.primaryContainer
              : AppTheme.borderColor,
          width: isCompleted || isInProgress ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Module number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: module['iconBg'] as Color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                module['icon'] as IconData,
                size: 18,
                color: module['iconColor'] as Color,
              ),
            ),
            const SizedBox(width: 12),

            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        module['duration'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppTheme.textLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          module['category'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
