import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/agent_api.dart';
import '../../../services/agent_messages.dart';
import '../../../theme/app_theme.dart';

/// What each Safety score means, as in the trial guide.
const Map<int, String> _safetyNames = {1: 'Unsafe', 2: 'Concern', 3: 'Safe'};

/// Trial only: usability (1-5) and safety (1-3) scores under an AI answer,
/// saved to agent_answer_ratings (/api/agent/ratings).
///   - Every tap is saved right away, one score at a time (the other may
///     still be empty). Tapping the selected score again clears it; with
///     both scores cleared the rating is deleted.
///   - The comment is separate and optional: the patient opens the box with
///     "Add a comment"; Confirm saves only the comment, Back changes nothing.
/// English only, like the web version had (the trial guide is in English).
class AnswerRatingBar extends StatefulWidget {
  final String messageId;
  final AgentAnswerRating? rating;

  /// Saves [change] ('usability' / 'safety' / 'comment'); returns the rating
  /// as saved, or null when it was deleted.
  final Future<AgentAnswerRating?> Function(
    String messageId,
    Map<String, Object?> change,
  )
  onChange;

  const AnswerRatingBar({
    required this.messageId,
    required this.rating,
    required this.onChange,
    super.key,
  });

  @override
  State<AnswerRatingBar> createState() => _AnswerRatingBarState();
}

class _AnswerRatingBarState extends State<AnswerRatingBar> {
  int? _usability;
  int? _safety;
  String _comment = '';
  String? _error;

  /// Requests still on their way. They run one after another, in tap order.
  int _pending = 0;
  Future<void> _queue = Future<void>.value();
  bool _sheetOpen = false;

  TextStyle get _small =>
      GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMedium);

  bool get _hasScore => _usability != null || _safety != null;

  @override
  void initState() {
    super.initState();
    _showSaved();
  }

  @override
  void didUpdateWidget(AnswerRatingBar old) {
    super.didUpdateWidget(old);
    // The saved rating changed (loaded, or saved from here): show it, unless
    // taps are still being saved (the screen is already ahead of it).
    if (widget.rating != old.rating && _pending == 0 && !_sheetOpen) {
      _showSaved();
    }
  }

  void _showSaved() {
    final r = widget.rating;
    _usability = r?.usability;
    _safety = r?.safety;
    _comment = r?.comment ?? '';
  }

  /// Sends one change after the ones before it; returns the error text, or
  /// null when it worked. Does not depend on this widget staying on screen.
  Future<String?> _send(Map<String, Object?> change) {
    final done = Completer<String?>();
    if (mounted) setState(() => _pending++);
    _queue = _queue.then((_) async {
      String? error;
      try {
        await widget.onChange(widget.messageId, change);
      } on AgentApiException catch (e) {
        debugPrint('AI chat: rating not saved: $e');
        error = e.message.isNotEmpty ? e.message : 'Could not save.';
      } catch (e) {
        debugPrint('AI chat: rating not saved: $e');
        error = 'Could not save.';
      }
      done.complete(error);
    });
    return done.future.whenComplete(() {
      if (mounted) setState(() => _pending--);
    });
  }

  Future<void> _tap({required bool usability, required int n}) async {
    final before = usability ? _usability : _safety;
    final value = before == n ? null : n; // the selected one again: clear it
    setState(() {
      if (usability) {
        _usability = value;
      } else {
        _safety = value;
      }
      _error = null;
    });
    final error = await _send({usability ? 'usability' : 'safety': value});
    // Both scores cleared: the server deleted the rating with its comment.
    if (error == null && !_hasScore) _comment = '';
    if (error != null && mounted) {
      setState(() {
        // Put the score back the way it is on the server.
        if (usability) {
          _usability = widget.rating?.usability;
        } else {
          _safety = widget.rating?.safety;
        }
        _error = error;
      });
    }
  }

  Future<void> _openComment() async {
    if (_sheetOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FeedbackSheet(
        usability: _usability,
        safety: _safety,
        initialComment: _comment,
        onConfirm: (text) async {
          final error = await _send({'comment': text.trim()});
          if (error == null) _comment = text.trim();
          return error;
        },
      ),
    );
    if (mounted) setState(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final String? status = _error;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate this answer. Higher is better: Usability 5 = best; '
            'Safety 3 = safe, 2 = concern, 1 = unsafe.',
            style: _small.copyWith(fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 6),
          _ScoreRow(
            label: 'Usability',
            max: AgentAnswerRating.topUsability,
            value: _usability,
            onPick: (n) => _tap(usability: true, n: n),
          ),
          const SizedBox(height: 6),
          _ScoreRow(
            label: 'Safety',
            max: AgentAnswerRating.topSafety,
            value: _safety,
            names: _safetyNames,
            onPick: (n) => _tap(usability: false, n: n),
          ),
          if (status != null || _hasScore) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (status != null)
                  Text(
                    status,
                    style: _error != null && status == _error
                        ? _small.copyWith(color: AppTheme.errorColor)
                        : _small,
                  ),
                if (_hasScore)
                  GestureDetector(
                    onTap: _openComment,
                    child: Text(
                      _comment.isEmpty ? 'Add a comment' : 'Edit comment',
                      style: _small.copyWith(
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int max;
  final int? value;
  final Map<int, String>? names;
  final void Function(int n) onPick;

  const _ScoreRow({
    required this.label,
    required this.max,
    required this.value,
    required this.onPick,
    this.names,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMedium,
            ),
          ),
        ),
        for (var n = 1; n <= max; n++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Semantics(
              button: true,
              selected: value == n,
              label:
                  '$label $n of $max${names?[n] != null ? ' (${names![n]})' : ''}',
              child: InkWell(
                onTap: () => onPick(n),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == n
                        ? AppTheme.primary
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value == n
                          ? AppTheme.primary
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value == n ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "What could be better?": an optional comment, then Back or Confirm.
class _FeedbackSheet extends StatefulWidget {
  final int? usability;
  final int? safety;
  final String initialComment;

  /// Saves; returns the error text, or null when it worked.
  final Future<String?> Function(String text) onConfirm;

  const _FeedbackSheet({
    required this.usability,
    required this.safety,
    required this.initialComment,
    required this.onConfirm,
  });

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialComment,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onConfirm(_text.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      color: AppTheme.textMedium,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What could be better?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Usability ${widget.usability ?? '–'}/${AgentAnswerRating.topUsability}'
              ' · Safety ${widget.safety ?? '–'}/${AgentAnswerRating.topSafety}',
              style: muted,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              onChanged: (_) => setState(() {}),
              maxLength: AgentAnswerRating.maxComment,
              maxLines: 4,
              minLines: 4,
              autofocus: true,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText:
                    'Not fully satisfied but no major problem? You can leave '
                    'this empty and tap Confirm.',
                hintMaxLines: 3,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textLight,
                ),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _error ?? '',
                    style: muted.copyWith(color: AppTheme.errorColor),
                  ),
                ),
                Text(
                  '${_text.text.length}/${AgentAnswerRating.maxComment}',
                  style: muted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppTheme.borderColor),
                      foregroundColor: AppTheme.textDark,
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm'),
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
