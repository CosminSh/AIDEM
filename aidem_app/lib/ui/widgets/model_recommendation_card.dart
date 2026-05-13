import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../services/model_setup_service.dart';
import 'tactical_container.dart';

class ModelRecommendationCard extends StatelessWidget {
  final bool compact;

  const ModelRecommendationCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return TacticalContainer(
      padding: EdgeInsets.all(compact ? 14 : 16),
      showGlow: false,
      borderColor: AppColors.brandAi.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandAi.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brandAi.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppColors.brandAi,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended model',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ModelSetupService.recommendedModelName,
                      style: GoogleFonts.inter(
                        color: AppColors.brandAi,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Download gemma-4-E2B-it.litertlm from Hugging Face, then use Select local file. '
            'AIDEM can try other local LLM files too, but it is optimized and tested with this Gemma 4 LiteRT model.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(ModelSetupService.recommendedModelPageUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text('Open Gemma 4 LiteRT page'),
            ),
          ),
        ],
      ),
    );
  }
}
