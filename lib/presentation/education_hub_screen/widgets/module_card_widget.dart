import '../../../core/app_export.dart';

class ModuleCardWidget extends StatefulWidget {
  final Map<String, dynamic> module;
  final int animationIndex;
  final VoidCallback onTap;

  const ModuleCardWidget({
    required this.module,
    required this.animationIndex,
    required this.onTap,
    super.key,
  });

  @override
  State<ModuleCardWidget> createState() => _ModuleCardWidgetState();
}

class _ModuleCardWidgetState extends State<ModuleCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Heart Health':
        return const Color(0xFFFFE4E6);
      case 'Sleep Health':
        return const Color(0xFFE0F2FE);
      case 'Emotional Support & Resources':
        return const Color(0xFFEDE9FE);
      case 'Resources':
        return const Color(0xFFDCFCE7);
      default:
        return AppTheme.primaryContainer;
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category) {
      case 'Heart Health':
        return const Color(0xFFBE123C);
      case 'Sleep Health':
        return const Color(0xFF0369A1);
      case 'Emotional Support & Resources':
        return AppTheme.purple;
      case 'Resources':
        return const Color(0xFF15803D);
      default:
        return AppTheme.primary;
    }
  }

  Widget _buildStatusIndicator(String status) {
    switch (status) {
      case 'completed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Completed',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case 'in_progress':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'In Progress',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withAlpha(153),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Available',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 80 + widget.animationIndex * 60);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    Future.delayed(delay, () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final category = module['category'] as String;
    final cardBg = _getCategoryColor(category);
    final catColor = _getCategoryTextColor(category);
    final status = module['status'] as String;
    final isCompleted = status == 'completed';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: isCompleted ? cardBg.withAlpha(153) : cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.secondary.withAlpha(77)
                      : catColor.withAlpha(38),
                ),
              ),
              child: Stack(
                children: [
                  // Completed overlay
                  if (isCompleted)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      // Text content
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: catColor.withAlpha(31),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: catColor,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                module['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? AppTheme.textMedium
                                      : AppTheme.textDark,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  _buildStatusIndicator(status),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(179),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 11,
                                          color: AppTheme.textMedium,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          module['duration'] as String,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMedium,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Thumbnail image — IgnorePointer prevents image from absorbing taps
                      IgnorePointer(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: SizedBox(
                            width: 110,
                            height: 130,
                            child: CustomImageWidget(
                              imageUrl: module['imageUrl'] as String,
                              width: 110,
                              height: 130,
                              fit: BoxFit.cover,
                              semanticLabel: module['semanticLabel'] as String,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
