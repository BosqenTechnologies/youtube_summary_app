import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart'; 

import 'package:youtube_summary_app/core/constants/app_strings.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/channel_screen.dart';
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

  Future<void> _showLogoutDialog(BuildContext context, Color primaryColor, Color primaryText, Color secondaryText, Color cardColor) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
          title: Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText, fontSize: AppDimensions.fontTitleMedium),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: secondaryText, fontSize: AppDimensions.fontNormal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: Text('Cancel', style: TextStyle(color: secondaryText, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: AppColors.textLight,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusNormal)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- 4-Color System Setup ---
    final primaryColor = isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final primaryText = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText = isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardColor = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.lightSurfaceContainerLowest;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.appName,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: AppDimensions.fontTitleMedium,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: primaryColor),
            onPressed: () => _showLogoutDialog(context, primaryColor, primaryText, secondaryText, cardColor),
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChannelsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium, 
            vertical: AppDimensions.paddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.distillNoise,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimensions.fontTitleLarge,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              Text(
                AppStrings.distillSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimensions.fontNormal,
                  color: secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLarge),

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
                  margin: const EdgeInsets.only(top: AppDimensions.spacingLarge),
                  padding: const EdgeInsets.all(AppDimensions.paddingNormal),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                    border: Border.all(
                      color: AppColors.errorRed.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorRed),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.errorRed, fontSize: AppDimensions.fontSmall),
                        ),
                      ),
                    ],
                  ),
                ),

              if (state.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXLarge),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),

              if (state.summary != null && !state.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacingLarge),
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
                const SizedBox(height: AppDimensions.spacingLarge),
                _buildFeatureCard(
                  icon: Icons.speed,
                  title: 'Instant Insights',
                  description: 'Get the core message of any video in seconds, not minutes.',
                  primaryColor: primaryColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  cardColor: cardColor,
                ),
                const SizedBox(height: AppDimensions.spacingNormal),
                _buildFeatureCard(
                  icon: Icons.format_list_bulleted,
                  title: 'Structured Chapters',
                  description: 'Summaries are broken down into logical, easy-to-read sections.',
                  primaryColor: primaryColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  cardColor: cardColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon, 
    required String title, 
    required String description,
    required Color primaryColor,
    required Color primaryText,
    required Color secondaryText,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 28),
          const SizedBox(height: AppDimensions.spacingNormal),
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimensions.fontButton,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            description,
            style: TextStyle(
              fontSize: AppDimensions.fontSmall,
              color: secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}