import 'package:flutter/material.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';

class InfoTipCard extends StatelessWidget {
  const InfoTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryText = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final inputFill = isDark ? AppColors.darkSurfaceContainerLow : AppColors.lightSurfaceContainerLow;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingNormal),
      padding: const EdgeInsets.all(AppDimensions.paddingNormal),
      decoration: BoxDecoration(
        color: inputFill, // Fits perfectly with the 4-color system
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.accentYellow.withValues(alpha: 0.3)), // Subtle yellow glow
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.accentYellow, // Semantic Yellow
            size: 32,
          ),
          const SizedBox(width: AppDimensions.spacingNormal),
          Expanded(
            child: Text(
              'Get instant summaries of YouTube videos for quick insights.',
              style: TextStyle(
                color: primaryText,
                fontSize: AppDimensions.fontSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}