import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/subscriptions_screen.dart';
import '../state/summary_provider.dart';
import '../widgets/url_input_card.dart';
import '../widgets/summary_result_card.dart';

class SummaryHomeScreen extends ConsumerStatefulWidget {
  const SummaryHomeScreen({super.key});

  @override
  ConsumerState<SummaryHomeScreen> createState() => _SummaryHomeScreenState();
}

class _SummaryHomeScreenState extends ConsumerState<SummaryHomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_urlController.text.isNotEmpty) {
      await ref.read(summaryProvider.notifier).summarize(_urlController.text);
    } else {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textGrey, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); 
                await Supabase.instance.client.auth.signOut(); 
              },
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TubeSum',
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryRed),
            onPressed: () => _showLogoutDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.primaryRed),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                AppStrings.distillNoise,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.distillSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              UrlInputCard(
                controller: _urlController,
                onSummarize: () {
                  if (_urlController.text.isNotEmpty) {
                    ref.read(summaryProvider.notifier).summarize(_urlController.text);
                  }
                },
              ),

              if (state.error != null && !state.isLoading)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  ),
                ),

              if (state.summary != null && !state.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: SummaryResultCard(
                    videoId: state.summary!.videoId,
                    thumbnailUrl: state.summary!.thumbnailUrl,
                    title: state.summary!.title,
                    channelName: state.summary!.channelName,
                    summary: state.summary!.summaryText,
                    fullTranscript: state.summary!.fullTranscript,
                    videoUrl: state.summary!.videoUrl,
                    channelUrl: state.summary!.channelUrl,
                    channelProfileSummary: state.summary!.channelProfileSummary,
                    previousSummaries: state.summary!.previousSummaries,
                    relevanceReport: state.summary!.relevanceReport,
                  ),
                )
              else if (!state.isLoading && state.error == null) ...[
                const SizedBox(height: 24),
                _buildFeatureCard(
                  icon: Icons.speed,
                  title: 'Instant Insights',
                  description: 'Get the core message of any video in seconds, not minutes.',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.format_list_bulleted,
                  title: 'Structured Chapters',
                  description: 'Summaries are broken down into logical, easy-to-read sections.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}