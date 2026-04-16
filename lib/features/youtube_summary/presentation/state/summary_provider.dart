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

  VideoSummary({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.summaryText,
    required this.fullTranscript,
    required this.videoUrl,
    required this.videoId,
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

  // ✅ FIXED: Use boolean flags to explicitly clear nullable fields.
  // The old pattern (error ?? this.error) never cleared error when null was passed.
  SummaryState copyWith({
    bool? isLoading,
    String? error,
    VideoSummary? summary,
    bool clearError = false,      // ← pass clearError: true to set error → null
    bool clearSummary = false,    // ← pass clearSummary: true to set summary → null
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
    // ✅ FIXED: clearError: true actually sets error to null now
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSummary: true,
    );

    try {
      // Step 1: Extract from YouTube (uses fallback if blocked)
      final videoData = await _extractionService.fetchVideoData(url);

      // Step 2: Save to Supabase
      await _databaseService.saveVideoData(videoData);

      // Step 3: Update UI with result
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