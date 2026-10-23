import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/assistance_service.dart';
import '../../theme/app_theme.dart';
import 'my_assistance_requests_screen.dart';

/// Opens the "I need assistance" form. Returns the created request, or null if
/// the user closed the sheet without sending. Shows a confirmation on success.
Future<AssistanceRequest?> showAssistanceRequestSheet(
  BuildContext context, {
  bool fromRequestList = false,
}) async {
  final created = await showModalBottomSheet<AssistanceRequest>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    // The list is opened with the caller's context: the sheet's own context
    // is gone once it is popped.
    builder: (_) => _AssistanceRequestSheet(
      showListLink: !fromRequestList,
      onOpenList: () => openMyAssistanceRequests(context),
    ),
  );
  if (created != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textDark,
        content: const Text(
          'Request sent. A team member will follow up with you.',
        ),
        action: fromRequestList
            ? null
            : SnackBarAction(
                label: 'View',
                textColor: AppTheme.primaryContainer,
                onPressed: () {
                  if (context.mounted) openMyAssistanceRequests(context);
                },
              ),
      ),
    );
  }
  return created;
}

class _AssistanceRequestSheet extends StatefulWidget {
  final VoidCallback onOpenList;
  final bool showListLink;
  const _AssistanceRequestSheet({
    required this.onOpenList,
    required this.showListLink,
  });

  @override
  State<_AssistanceRequestSheet> createState() => _AssistanceRequestSheetState();
}

class _AssistanceRequestSheetState extends State<_AssistanceRequestSheet> {
  final TextEditingController _controller = TextEditingController();
  // One id per request: a retry re-sends the same id, so no duplicate alerts.
  final String _requestId = AssistanceService.instance.newRequestId();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      // Clear a previous error and refresh the Send button state.
      setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final created = await AssistanceService.instance.submit(
        requestId: _requestId,
        message: _controller.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on AssistanceException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I need assistance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (widget.showListLink)
                  TextButton(
                  onPressed: _sending
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onOpenList();
                        },
                  child: const Text('My requests'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tell the research team what you need help with. A team member '
              'will follow up, usually by message in Care Team chat.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.emergency_outlined,
                    size: 18,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is not monitored around the clock. If this is an '
                      'emergency, call 911.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_sending,
              minLines: 4,
              maxLines: 8,
              maxLength: AssistanceService.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'For example: "I have a question about my medication" or '
                    '"The video in Session 3 won\'t play."',
                hintMaxLines: 3,
                filled: true,
                fillColor: AppTheme.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sending ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _canSend ? _send : null,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_sending ? 'Sending…' : 'Send request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
