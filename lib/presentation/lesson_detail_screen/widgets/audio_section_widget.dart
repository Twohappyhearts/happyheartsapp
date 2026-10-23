import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';

// Conditional imports: stub used on mobile, web_impl on web
import 'audio_section_web_stub.dart'
    if (dart.library.html) 'audio_section_web_impl.dart'
    as audio_platform;

/// Audio version of the lesson (SoundCloud link set in the dashboard).
class AudioSectionWidget extends StatefulWidget {
  final String audioUrl;
  final String duration;

  /// Player state changes (play | pause | ended).
  final void Function(String state)? onPlayerState;

  const AudioSectionWidget({
    required this.audioUrl,
    required this.duration,
    this.onPlayerState,
    super.key,
  });

  static bool isSoundCloud(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'soundcloud.com' || host.endsWith('.soundcloud.com');
  }

  @override
  State<AudioSectionWidget> createState() => _AudioSectionWidgetState();
}

class _AudioSectionWidgetState extends State<AudioSectionWidget> {
  Object? _mobileController;
  late final bool _embeddable = AudioSectionWidget.isSoundCloud(widget.audioUrl);

  @override
  void initState() {
    super.initState();
    if (_embeddable && !kIsWeb) {
      _mobileController = audio_platform.createSoundCloudController(
        widget.audioUrl,
        onState: (state) => widget.onPlayerState?.call(state),
      );
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.audioUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (same style as the other lesson sections)
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.headphones_rounded,
                size: 20,
                color: Color(0xFFE11D48),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Audio Lesson',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              if (_embeddable)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 166,
                    child: audio_platform.buildSoundCloudPlayer(
                      widget.audioUrl,
                      _mobileController,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openExternally,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open audio'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    if (widget.duration.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.duration,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Listen to this lesson',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
