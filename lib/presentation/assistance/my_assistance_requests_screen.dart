import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_language.dart';
import '../../services/assistance_service.dart';
import '../../theme/app_theme.dart';
import 'assistance_request_sheet.dart';

/// Opens the patient's list of assistance requests.
Future<void> openMyAssistanceRequests(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MyAssistanceRequestsScreen()));
}

class MyAssistanceRequestsScreen extends StatefulWidget {
  const MyAssistanceRequestsScreen({super.key});

  @override
  State<MyAssistanceRequestsScreen> createState() =>
      _MyAssistanceRequestsScreenState();
}

class _MyAssistanceRequestsScreenState extends State<MyAssistanceRequestsScreen>
    with WidgetsBindingObserver {
  List<AssistanceRequest>? _requests;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Statuses change on the staff side; refresh when the app comes back.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list = await AssistanceService.instance.fetchMine();
      if (!mounted) return;
      setState(() {
        _requests = list;
        _error = null;
      });
    } on AssistanceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (_requests != null) {
        // Keep showing the last list; just tell the user the refresh failed.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(e.message),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newRequest() async {
    final created = await showAssistanceRequestSheet(
      context,
      fromRequestList: true,
    );
    if (created == null || !mounted) return;
    setState(() {
      final list = List<AssistanceRequest>.of(_requests ?? const []);
      list.removeWhere((r) => r.id == created.id);
      _requests = [created, ...list];
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = _requests;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          context.l10n.requestsTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newRequest,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l10n.requestsNew),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: requests == null
            ? _buildPlaceholder()
            : requests.isEmpty
            ? _buildEmpty()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _RequestCard(request: requests[i]),
              ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    // Scrollable so pull-to-refresh works in every state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: _error == null
                ? const CircularProgressIndicator(color: AppTheme.primary)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.errorColor,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 96),
        const Icon(Icons.support_rounded, color: AppTheme.textLight, size: 48),
        const SizedBox(height: 12),
        Text(
          context.l10n.requestsEmptyTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.requestsEmptyBody,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AssistanceRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color, icon) = switch (request.status) {
      AssistanceStatus.newRequest => (
        l10n.requestStatusSent,
        AppTheme.primary,
        Icons.schedule_rounded,
      ),
      AssistanceStatus.acknowledged => (
        l10n.requestStatusSeen,
        AppTheme.warningColor,
        Icons.visibility_outlined,
      ),
      AssistanceStatus.resolved => (
        l10n.requestStatusResolved,
        AppTheme.secondary,
        Icons.check_circle_outline_rounded,
      ),
    };

    final acknowledged = request.acknowledgedAt;
    final resolved = request.resolvedAt;
    final detail = switch (request.status) {
      AssistanceStatus.newRequest => l10n.requestWaiting,
      AssistanceStatus.acknowledged =>
        acknowledged == null
            ? l10n.requestFollowing
            : l10n.requestFollowingSince(l10n.relativeDateTime(acknowledged)),
      AssistanceStatus.resolved =>
        resolved == null
            ? l10n.requestResolved
            : l10n.requestResolvedSince(l10n.relativeDateTime(resolved)),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.relativeDateTime(request.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.45,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
