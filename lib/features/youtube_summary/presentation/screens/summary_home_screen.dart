import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/summary_provider.dart';
import '../widgets/url_input_card.dart';
import '../widgets/summary_result_card.dart';
import '../widgets/info_tip_card.dart';

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

  // The function that runs when the user pulls down to refresh
  Future<void> _handleRefresh() async {
    if (_urlController.text.isNotEmpty) {
      // Re-fetch the summary if a URL is already in the box
      await ref.read(summaryProvider.notifier).summarize(_urlController.text);
    } else {
      // If the box is empty, just show the loading spinner for 1 second for good UX
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // Function to show the scrollable transcript bottom sheet
  void _showFullTranscript(BuildContext context, String transcript) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more than half the screen
      backgroundColor: Colors.transparent, // Makes the rounded corners look correct
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85, // Takes up 85% of screen height
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Full Transcript',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              
              // Scrollable Transcript Text
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    transcript,
                    style: const TextStyle(
                      fontSize: 16, 
                      height: 1.6, // Adds nice line spacing for readability
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TubeSum'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
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
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
                
              // 🔥 NEW: Wrapped Result Card and New Summary Button in a spread operator collection
              if (state.summary != null && !state.isLoading) ...[
                SummaryResultCard(
                  thumbnailUrl: state.summary!.thumbnailUrl,
                  title: state.summary!.title,
                  channelName: state.summary!.channelName,
                  summary: state.summary!.summaryText,
                  onViewTranscript: () {
                    _showFullTranscript(context, state.summary!.summaryText);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 🔥 NEW: "Start New Summary" Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        'Start New Summary',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // 1. Clear the text field
                        _urlController.clear();
                        
                        // 2. Instantly wipe the state clean to give a fresh screen
                        ref.invalidate(summaryProvider);
                      },
                    ),
                  ),
                ),
              ],
                
              const InfoTipCard(),
            ],
          ),
        ),
      ),
    );
  }
}