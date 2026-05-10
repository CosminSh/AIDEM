import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';
import '../widgets/tactical_container.dart';

class SessionSummaryScreen extends StatelessWidget {
  final List<ChatMessage> history;
  // final List<GpsCoordinates> locationLog; // Future: pass from SQLite

  const SessionSummaryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: "Share summary",
            onPressed: () {
              // Share session text
            },
          ),
        ],
      ),
      body: AidemBackground(
        child: Column(
          children: [
            _buildInfoBanner(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: history.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final msg = history[index];
                  return _buildSummaryItem(msg);
                },
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
            Icon(Icons.history, color: AppColors.accentBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Show this timeline to rescuers if it helps explain what happened.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
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
}
