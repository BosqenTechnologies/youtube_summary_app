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
          // This stretches the button to full width for a better mobile UI
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            // 1. The Text Input Field (Now takes up the whole width)
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
                ],
              ),
            ),
            
            const SizedBox(height: 16), // Spacing between input and button
            
            // 2. The Summarize Button (Now below the input)
            ElevatedButton(
              onPressed: onSummarize,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14), // Made slightly taller for better tap area
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Summarize',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 3. The Hint Text
            const Text(
              'Paste a YouTube URL to generate a summary.',
              textAlign: TextAlign.center, // Centered to match the new layout
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