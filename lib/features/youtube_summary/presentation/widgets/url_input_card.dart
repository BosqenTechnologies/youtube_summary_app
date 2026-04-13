import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.play_circle_fill, color: Colors.red),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter YouTube video URL',
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onSummarize,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Summarize'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Paste a YouTube URL to generate a summary.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
