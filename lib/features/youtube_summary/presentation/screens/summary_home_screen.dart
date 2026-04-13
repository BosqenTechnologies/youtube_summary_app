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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TubeSum'),
      ),
      body: SingleChildScrollView(
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
                onViewTranscript: () {},
              ),
            const InfoTipCard(),
          ],
        ),
      ),
    );
  }
}
