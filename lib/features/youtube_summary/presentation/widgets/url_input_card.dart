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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL Input Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Light grey input background
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://www.youtube.com/watch...',
                hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                prefixIcon: Icon(Icons.link, color: Colors.blueGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
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
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
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