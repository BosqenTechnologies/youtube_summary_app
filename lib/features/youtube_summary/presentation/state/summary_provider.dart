import 'package:flutter_riverpod/flutter_riverpod.dart';

class SummaryState {
  final bool isLoading;
  final String? error;
  final VideoSummary? summary;

  SummaryState({
    this.isLoading = false,
    this.error,
    this.summary,
  });

  SummaryState copyWith({
    bool? isLoading,
    String? error,
    VideoSummary? summary,
  }) {
    return SummaryState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      summary: summary ?? this.summary,
    );
  }
}

class VideoSummary {
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String summaryText;

  VideoSummary({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.summaryText,
  });
}

class SummaryNotifier extends StateNotifier<SummaryState> {
  SummaryNotifier() : super(SummaryState());

  Future<void> summarize(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock data based on the screenshot for demonstration
    state = state.copyWith(
      isLoading: false,
      summary: VideoSummary(
        title: 'Top 5 AI Stocks To Buy in 2024',
        channelName: 'Investing Insights',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg', // Placeholder
        summaryText: 'Top 5 AI stocks to consider for 2024 are highlighted, focusing on companies leading in AI innovation and poised for growth. Financial performance and future potential of these stocks are discussed, with emphasis on their role in the AI sector.\n• Key AI companies like Nvidia and Google are mentioned as top picks.',
      ),
    );
  }
}

final summaryProvider = StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  return SummaryNotifier();
});
