import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/protocol.dart';
import '../widgets/diagram_card.dart';
import '../widgets/tactical_container.dart';

class StepDetailScreen extends StatelessWidget {
  final ProtocolNode node;
  final String? diagramPath; // Path to asset image if available
  final String? diagramCaption;

  const StepDetailScreen({
    super.key,
    required this.node,
    this.diagramPath,
    this.diagramCaption,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step Details")),
      body: AidemBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: TacticalContainer(
            showGlow: false,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (node.source != null) ...[
                  Text(
                    "Source: ${node.source!}",
                    style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  node.question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                if (diagramPath != null)
                  DiagramCard(
                    imagePath: diagramPath!,
                    caption: diagramCaption ?? "Visual guide for this step.",
                  ),
                const SizedBox(height: 24),
                const SectionLabel(label: "Additional Guidance"),
                const SizedBox(height: 12),
                const Text(
                  "Follow the instructions exactly as shown. If you are unsure, prioritize safety and stabilization. Contact rescuers as soon as signal becomes available.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text("Return to session"),
          ),
        ),
      ),
    );
  }
}
