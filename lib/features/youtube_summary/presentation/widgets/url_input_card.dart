import 'package:flutter/material.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';

class UrlInputCard extends StatelessWidget {
  final VoidCallback onSummarize;
  final TextEditingController controller;

  const UrlInputCard({
    super.key,
    required this.onSummarize,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- 4-Color System Setup ---
    final primaryColor = isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final primaryText = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText = isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final cardColor = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.lightSurfaceContainerLowest;
    final inputFill = isDark ? AppColors.darkSurfaceContainerLow : AppColors.lightSurfaceContainerLow;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL Input Field
          Container(
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(color: primaryText, fontSize: AppDimensions.fontNormal),
              decoration: InputDecoration(
                hintText: 'https://www.youtube.com/watch...',
                hintStyle: TextStyle(color: secondaryText, fontSize: AppDimensions.fontSmall),
                prefixIcon: Icon(Icons.link, color: secondaryText),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingNormal),
              ),
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingNormal),
          
          // Summarize Button
          SizedBox(
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: onSummarize,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: AppColors.textLight, // ✨ THE FIX: Forces white text & icon
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome, size: 20, color: AppColors.textLight),
                  SizedBox(width: AppDimensions.spacingSmall),
                  Text(
                    AppStrings.summarize,
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight, // ✨ Explicitly white
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}