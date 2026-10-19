import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import './assessment_webview_screen.dart';

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  static const _foodResourcesUrl =
      'https://ci-redcap.hs.uci.edu/surveys/?s=3JAA7JRPHFEC4WY3';
  static const _mentalWellbeingUrl =
      'https://ci-redcap.hs.uci.edu/surveys/?s=RC4XD9NPP9J7XKFL';

  void _openAssessment(BuildContext context, String title, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssessmentWebViewScreen(title: title, url: url),
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
                    const Text(
                      'Assessments',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track your mental and physical health with these validated screening tools.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Emotional Assessment ──────────────────────────────
                  _SectionHeader(
                    icon: Icons.psychology_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                    title: 'Emotional Assessment',
                  ),
                  const SizedBox(height: 12),
                  _AssessmentCard(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFDB2777),
                    iconBg: const Color(0xFFFCE7F3),
                    title: 'Mental Well-being Quiz',
                    description:
                        'A validated screening tool to assess your overall mental wellness and emotional health.',
                    frequency: 'Monthly',
                    frequencyColor: const Color(0xFF7C3AED),
                    frequencyBg: const Color(0xFFEDE9FE),
                    duration: '~5 min',
                    onTap: () => _openAssessment(
                      context,
                      'Mental Well-being Quiz',
                      _mentalWellbeingUrl,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Basic Needs Assessment ────────────────────────────
                  _SectionHeader(
                    icon: Icons.assignment_rounded,
                    iconColor: const Color(0xFF0369A1),
                    iconBg: const Color(0xFFE0F2FE),
                    title: 'Basic Needs Assessment',
                  ),
                  const SizedBox(height: 12),
                  _AssessmentCard(
                    icon: Icons.restaurant_rounded,
                    iconColor: const Color(0xFF15803D),
                    iconBg: const Color(0xFFDCFCE7),
                    title: 'Food Resources Quiz',
                    description:
                        'Find out about food assistance resources available to you and your family.',
                    frequency: 'As Needed',
                    frequencyColor: const Color(0xFF0369A1),
                    frequencyBg: const Color(0xFFE0F2FE),
                    duration: '~4 min',
                    onTap: () => _openAssessment(
                      context,
                      'Food Resources Quiz',
                      _foodResourcesUrl,
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assessment Card
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String frequency;
  final Color frequencyColor;
  final Color frequencyBg;
  final String duration;
  final VoidCallback onTap;

  const _AssessmentCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.frequency,
    required this.frequencyColor,
    required this.frequencyBg,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Badges row
                    Row(
                      children: [
                        // Frequency badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: frequencyBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            frequency,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: frequencyColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Duration badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              duration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Start Assessment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
