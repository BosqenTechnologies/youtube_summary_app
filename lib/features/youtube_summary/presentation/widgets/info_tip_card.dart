import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class InfoTipCard extends StatelessWidget {
  const InfoTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.accentYellow,
            size: 32,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Get instant summaries of YouTube videos for quick insights.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
