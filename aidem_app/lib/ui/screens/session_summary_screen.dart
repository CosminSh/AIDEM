import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';
import '../../services/gps_service.dart';
import '../widgets/tactical_container.dart';

class SessionSummaryScreen extends StatelessWidget {
  final List<ChatMessage> history;
  final String situationSummary;
  final bool isPracticeMode;
  final String? currentNodeId;
  final List<GpsCoordinates> locationHistory;

  const SessionSummaryScreen({
    super.key,
    required this.history,
    this.situationSummary = '',
    this.isPracticeMode = false,
    this.currentNodeId,
    this.locationHistory = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: "Share summary",
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _buildShareText()));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rescue summary copied to clipboard.'),
                ),
              );
            },
          ),
        ],
      ),
      body: AidemBackground(
        child: Column(
          children: [
            _buildInfoBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSituationCard(context),
                  const SizedBox(height: 16),
                  _buildHandoffCard(context),
                  if (locationHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLocationTimelineCard(context),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Timeline',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < history.length; i++) ...[
                    _buildSummaryItem(history[i]),
                    if (i != history.length - 1) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text("Close and finish"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TacticalContainer(
        showGlow: false,
        borderRadius: AppColors.radius,
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              color: AppColors.accentBlue,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Professional handoff view: share location, situation, timeline, and actions already taken.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationCard(BuildContext context) {
    final summary = situationSummary.trim().isNotEmpty
        ? situationSummary.trim()
        : 'No structured situation summary has been created yet.';

    return TacticalContainer(
      showGlow: false,
      borderRadius: AppColors.radius,
      borderColor: AppColors.brandAi.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.brandAi,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Rescue Handoff',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.brandAi,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                isPracticeMode ? 'Practice/demo' : 'Emergency',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniPill(Icons.fact_check_outlined, 'Protocol-based'),
              _buildMiniPill(Icons.call_outlined, 'Call services first'),
              _buildMiniPill(Icons.lock_outline_rounded, 'Local timeline'),
              if (currentNodeId != null)
                _buildMiniPill(Icons.route_outlined, currentNodeId!),
            ],
          ),
          const SizedBox(height: 14),
          _buildCopyAction(context, 'Copy situation', summary),
        ],
      ),
    );
  }

  Widget _buildHandoffCard(BuildContext context) {
    final userMessages = history
        .where((message) => message.author == MessageAuthor.user)
        .map((message) => message.text)
        .toList();
    final actionsTaken = history
        .where((message) => message.author == MessageAuthor.ai)
        .skip(1)
        .take(3)
        .map((message) => message.text)
        .toList();

    final dispatcherScript = _buildDispatcherScript(userMessages);

    return TacticalContainer(
      showGlow: false,
      borderRadius: AppColors.radius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: AppColors.accentOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Dispatcher Script',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dispatcherScript,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _buildChecklistItem(
            'Known situation',
            situationSummary.isNotEmpty
                ? situationSummary
                : 'Review the timeline for details.',
          ),
          _buildChecklistItem(
            'Hazards',
            _findFirstMention(['danger', 'hazard', 'fire', 'cold', 'blood']) ??
                'Not confirmed yet.',
          ),
          _buildChecklistItem(
            'Actions already taken',
            actionsTaken.isEmpty
                ? 'No protocol actions logged yet.'
                : actionsTaken.join(' '),
          ),
          _buildChecklistItem(
            'Location',
            _findFirstMention(['gps', 'coordinate', 'location']) ??
                'Use the location button during the session.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCopyAction(
                  context,
                  'Copy script',
                  dispatcherScript,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCopyAction(
                  context,
                  'Copy report',
                  _buildShareText(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTimelineCard(BuildContext context) {
    final latest = locationHistory.last;
    final latestText =
        '${_formatDecimal(latest)}\n${latest.toDms()}'
        '${latest.altitude == null ? '' : '\nAltitude: ${latest.altitude!.toStringAsFixed(0)} m'}';

    return TacticalContainer(
      showGlow: false,
      borderRadius: AppColors.radius,
      borderColor: AppColors.accentBlue.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location_rounded,
                color: AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Location Timeline',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '${locationHistory.length} fix${locationHistory.length == 1 ? '' : 'es'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLocationRow('Latest decimal', _formatDecimal(latest)),
          _buildLocationRow('Latest DMS', latest.toDms()),
          if (latest.altitude != null)
            _buildLocationRow(
              'Altitude',
              '${latest.altitude!.toStringAsFixed(0)} m',
            ),
          const SizedBox(height: 4),
          _buildCopyAction(context, 'Copy latest location', latestText),
          const SizedBox(height: 12),
          for (final fix in locationHistory.reversed.take(5))
            _buildLocationFix(fix),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'Monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFix(GpsCoordinates fix) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Text(
            _formatTime(fix.timestamp),
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDecimal(fix),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: 'Monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyAction(BuildContext context, String label, String value) {
    return OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label copied.')));
      },
      icon: const Icon(Icons.copy_rounded, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildChecklistItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.brandAi,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(ChatMessage msg) {
    final isAi = msg.author == MessageAuthor.ai;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isAi ? "AIDEM asked" : "You responded",
              style: TextStyle(
                color: isAi ? AppColors.textSecondary : AppColors.accentBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          msg.text,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ],
    );
  }

  String _buildDispatcherScript(List<String> userMessages) {
    final summary = situationSummary.trim().isNotEmpty
        ? situationSummary.trim()
        : userMessages.take(2).join(' ');

    if (summary.isEmpty) {
      return 'I need emergency assistance. I am using AIDEM to keep a timeline. I can provide location, symptoms, hazards, and actions taken.';
    }

    return 'I need emergency assistance. Situation: $summary. I can provide GPS coordinates, current condition, hazards, and the timeline of first-aid actions already taken.';
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('AIDEM Rescue Summary');
    buffer.writeln(
      situationSummary.isNotEmpty
          ? situationSummary
          : 'No structured situation summary yet.',
    );
    buffer.writeln();
    buffer.writeln(_buildDispatcherScript(_userMessages()));
    if (locationHistory.isNotEmpty) {
      final latest = locationHistory.last;
      buffer.writeln();
      buffer.writeln('Latest GPS: ${_formatDecimal(latest)}');
      buffer.writeln('Latest DMS: ${latest.toDms()}');
      if (latest.altitude != null) {
        buffer.writeln('Altitude: ${latest.altitude!.toStringAsFixed(0)} m');
      }
    }
    buffer.writeln();
    buffer.writeln('Timeline entries: ${history.length}');
    return buffer.toString();
  }

  List<String> _userMessages() {
    return history
        .where((message) => message.author == MessageAuthor.user)
        .map((message) => message.text)
        .toList();
  }

  String _formatDecimal(GpsCoordinates fix) {
    return '${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)}';
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String? _findFirstMention(List<String> terms) {
    for (final message in history.reversed) {
      final lower = message.text.toLowerCase();
      if (terms.any(lower.contains)) {
        return message.text;
      }
    }
    return null;
  }
}
