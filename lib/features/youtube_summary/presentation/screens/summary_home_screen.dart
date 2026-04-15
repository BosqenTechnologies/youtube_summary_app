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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TubeSum'),
      ),
      // 🔥 NEW: Wrapped in RefreshIndicator 🔥
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          // 🔥 NEW: Forced physics so pull-to-refresh works even on short screens 🔥
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
                
              if (state.summary != null && !state.isLoading)
                SummaryResultCard(
                  thumbnailUrl: state.summary!.thumbnailUrl,
                  title: state.summary!.title,
                  channelName: state.summary!.channelName,
                  summary: state.summary!.summaryText,
                  fullTranscript: state.summary!.fullTranscript,
                ),
                
              const InfoTipCard(),
            ],
          ),
        ),
      ),
    );
  }
}