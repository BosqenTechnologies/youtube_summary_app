import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔥 Added Supabase import for logout
// Use Theme.of(context) instead of AppColors so UI follows active theme
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

  // 🔥 NEW: Logout Confirmation Dialog
  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                // 🔥 This instantly triggers AuthGate to show the AuthScreen
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: AppColors.primaryRed),
        //   onPressed: () {}, // Optional drawer logic later
        // ),
        centerTitle: true,
        title: Text(
          'TubeSum',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // 🔥 NEW: Logout Button
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.primary),
            onPressed: () => _showLogoutDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: theme.colorScheme.primary),
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
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                AppStrings.distillNoise,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface) ?? TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.distillSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, color: theme.textTheme.bodyMedium?.color, height: 1.4) ?? TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.4),
              ),
              const SizedBox(height: 32),

              // Input Card
              UrlInputCard(
                controller: _urlController,
                onSummarize: () {
                  if (_urlController.text.isNotEmpty) {
                    ref.read(summaryProvider.notifier).summarize(_urlController.text);
                  }
                },
              ),

              // Error State
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

              // Loading State
              if (state.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  ),
                ),

              // Result State OR Feature Cards
              if (state.summary != null && !state.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: SummaryResultCard(
                    thumbnailUrl: state.summary!.thumbnailUrl,
                    title: state.summary!.title,
                    channelName: state.summary!.channelName,
                    summary: state.summary!.summaryText,
                    fullTranscript: state.summary!.fullTranscript,
                    videoUrl: state.summary!.videoUrl,
                    videoId: state.summary!.videoId,
                  ),
                )
              else if (!state.isLoading && state.error == null) ...[
                // Feature Cards (Shown when idle)
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface) ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: theme.textTheme.bodyMedium?.color, height: 1.4) ?? const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}