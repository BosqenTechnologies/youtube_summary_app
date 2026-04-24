import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_summary_app/features/youtube_summary/data/services/database_service.dart';
import 'package:youtube_summary_app/features/youtube_summary/data/services/youtube_extraction_service.dart';

// ──────────────────────────────────────────────
// DATA MODEL
// ──────────────────────────────────────────────

class VideoSummary {
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String summaryText;
  final String fullTranscript;
  final String videoUrl;
  final String videoId;
  final String? channelUrl;
  final String? channelProfileSummary;
  final List<String> previousSummaries;

  VideoSummary({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.summaryText,
    required this.fullTranscript,
    required this.videoUrl,
    required this.videoId,
    this.channelUrl,
    this.channelProfileSummary,
    this.previousSummaries = const [],
  });
}

// ──────────────────────────────────────────────
// STATE
// ──────────────────────────────────────────────

class SummaryState {
  final bool isLoading;
  final String? error;
  final VideoSummary? summary;

  const SummaryState({
    this.isLoading = false,
    this.error,
    this.summary,
  });

  SummaryState copyWith({
    bool? isLoading,
    String? error,
    VideoSummary? summary,
    bool clearError = false,      
    bool clearSummary = false,    
  }) {
    return SummaryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      summary: clearSummary ? null : (summary ?? this.summary),
    );
  }
}

// ──────────────────────────────────────────────
// NOTIFIER
// ──────────────────────────────────────────────

class SummaryNotifier extends StateNotifier<SummaryState> {
  SummaryNotifier() : super(const SummaryState());

  final _extractionService = YouTubeExtractionService();
  final _databaseService = DatabaseService();

  Future<void> summarize(String url) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSummary: true,
    );

    try {
      final videoData = await _extractionService.fetchVideoData(url);

      await _databaseService.saveVideoData(videoData);

      final transcript = videoData['transcript'] as String;
      state = state.copyWith(
        isLoading: false,
        summary: VideoSummary(
          title: videoData['title'],
          channelName: videoData['channel_name'],
          thumbnailUrl:
              'https://img.youtube.com/vi/${videoData['video_id']}/0.jpg',
          summaryText: videoData['summary'] ?? (transcript.length > 300
              ? '${transcript.substring(0, 300)}...'
              : transcript),
          fullTranscript: transcript,
          videoUrl: videoData['video_url'] ?? url,
          videoId: videoData['video_id'],
          channelUrl: videoData['channel_url'],
          channelProfileSummary: videoData['channel_profile_summary'],
          previousSummaries: List<String>.from(videoData['previous_summaries'] ?? []),
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to process video: ${e.toString()}',
      );
    }
  }
}

// ──────────────────────────────────────────────
// PROVIDER
// ──────────────────────────────────────────────

final summaryProvider =
    StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  return SummaryNotifier();
});
