import 'package:flutter/material.dart';

class InfoTipCard extends StatelessWidget {
  const InfoTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: theme.colorScheme.secondary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Get instant summaries of YouTube videos for quick insights.',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
