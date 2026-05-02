import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';

class SessionSummaryScreen extends StatelessWidget {
  final List<ChatMessage> history;
  // final List<GpsCoordinates> locationLog; // Future: pass from SQLite

  const SessionSummaryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Session Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // Share session text
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final msg = history[index];
                return _buildSummaryItem(msg);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radius),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              child: const Text("CLOSE & FINISH"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: const Row(
        children: [
          Icon(Icons.history, color: AppColors.accentBlue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "This summary can be shown to rescuers to help them understand your timeline and location history.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
              isAi ? "AId ASKED" : "YOU RESPONDED",
              style: TextStyle(
                color: isAi ? AppColors.textSecondary : AppColors.accentBlue,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Text(
              "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
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
