import 'package:flutter/material.dart';

// UI uses Theme.of(context) so colors follow active theme

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL Input Field
          Container(
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor ?? const Color(0xFFF3F4F6), // Use theme input fill if available
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://www.youtube.com/watch...',
                hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                prefixIcon: Icon(Icons.link, color: theme.hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summarize Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: onSummarize,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Summarize',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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