import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../../theme/app_theme.dart';

import 'kahoot_section_web_stub.dart'
    if (dart.library.html) 'kahoot_section_web_impl.dart'
    as kahoot_platform;

class KahootSectionWidget extends StatefulWidget {
  final String kahootUrl;
  final String username;

  /// Already reported as finished (earlier visit or still being sent).
  final bool quizCompleted;

  /// "Start Kahoot! Game" tapped.
  final VoidCallback? onQuizStarted;

  /// "I finished the quiz" tapped (self-report; Kahoot can't tell us).
  final VoidCallback? onQuizCompleted;

  const KahootSectionWidget({
    required this.kahootUrl,
    required this.username,
    this.quizCompleted = false,
    this.onQuizStarted,
    this.onQuizCompleted,
    super.key,
  });

  @override
  State<KahootSectionWidget> createState() => _KahootSectionWidgetState();
}

class _KahootSectionWidgetState extends State<KahootSectionWidget> {
  bool _kahootStarted = false;
  bool _startedOnce = false;
  late bool _quizDone = widget.quizCompleted;
  Object? _mobileController;

  @override
  void didUpdateWidget(covariant KahootSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quizCompleted && !_quizDone) _quizDone = true;
  }

  void _markQuizFinished() {
    if (_quizDone) return;
    setState(() => _quizDone = true);
    widget.onQuizCompleted?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Nice work! Quiz marked as finished.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyUsername() {
    Clipboard.setData(ClipboardData(text: widget.username));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Username copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startKahoot() {
    // On mobile: create WebViewController loading HTML with iframe
    // On web: no controller needed — HtmlElementView iframe used directly
    if (!kIsWeb) {
      _mobileController = kahoot_platform.createKahootController(
        widget.kahootUrl,
      );
    }
    setState(() {
      _kahootStarted = true;
      _startedOnce = true;
    });
    widget.onQuizStarted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.purpleContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 20,
                color: AppTheme.purple,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Knowledge Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            if (_kahootStarted) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  _kahootStarted = false;
                  _mobileController = null;
                }),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textMedium,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Kahoot embed or card
        if (_kahootStarted) _buildKahootEmbed() else _buildKahootCard(),

        // Self-report, shown once the game was opened (or already reported).
        if (_startedOnce || _quizDone) ...[
          const SizedBox(height: 12),
          _buildQuizFinishedRow(),
        ],

        const SizedBox(height: 16),

        // Username copy row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Kahoot Username',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.purpleContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: AppTheme.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _copyUsername,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.purpleContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppTheme.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Use this username when prompted in the Kahoot game',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKahootCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.purple, Color(0xFF9F67FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purple.withAlpha(89),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Knowledge Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Test what you've learned with an interactive Kahoot! game",
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildBadgePill('⏱ ~5 min'),
              _buildBadgePill('✨ Interactive'),
              _buildBadgePill('🎉 Fun!'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startKahoot,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'Start Kahoot! Game',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.purple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The game will open embedded below when you tap the button above',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKahootEmbed() {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: kahoot_platform.buildKahootPlayer(
          widget.kahootUrl,
          _mobileController,
        ),
      ),
    );
  }

  Widget _buildQuizFinishedRow() {
    if (_quizDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF15803D)),
            SizedBox(width: 6),
            Text(
              'Quiz finished',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _markQuizFinished,
        icon: const Icon(Icons.flag_rounded, size: 18),
        label: const Text(
          'I finished the quiz',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.purple,
          side: const BorderSide(color: AppTheme.purple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBadgePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
