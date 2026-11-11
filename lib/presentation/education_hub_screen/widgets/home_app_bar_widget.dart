import '../../../core/app_export.dart';
import '../../../widgets/app_menu.dart';

/// Top of the Education tab: menu button, the patient's initial (opens
/// Profile) and a greeting.
///
/// The notification bell was removed: the app has no notifications yet, and
/// the bell always showed an unread dot and did nothing when tapped.
class HomeAppBarWidget extends StatelessWidget {
  final String userName;

  /// First letter of the patient's name ('' while the profile loads).
  final String initial;
  final VoidCallback onAvatarTap;

  const HomeAppBarWidget({
    required this.userName,
    required this.initial,
    required this.onAvatarTap,
    super.key,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Side menu
        const AppMenuButton(),
        const SizedBox(width: 10),
        // Avatar
        Semantics(
          button: true,
          label: 'Profile',
          child: GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(64),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: initial.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      )
                    : Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.isEmpty ? 'Hi 👋' : 'Hi, $userName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                _getTimeGreeting(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
