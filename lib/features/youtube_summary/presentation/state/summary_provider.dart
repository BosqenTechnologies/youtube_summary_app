import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_summary_app/features/youtube_summary/data/services/youtube_extraction_service.dart';

// ──────────────────────────────────────────────
// DATA MODEL
// ──────────────────────────────────────────────

class SimilarSummary {
  final String videoId;
  final String title;
  final String summary;
  final String transcript;
  final String channelName;
  final double similarity;

  SimilarSummary({
    required this.videoId,
    required this.title,
    required this.summary,
    required this.transcript,
    required this.channelName,
    required this.similarity,
  });

  factory SimilarSummary.fromJson(Map<String, dynamic> json) {
    return SimilarSummary(
      videoId: json['video_id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      transcript: json['transcript'] ?? '',
      channelName: json['channel_name'] ?? '',
      similarity: (json['similarity'] ?? 0.0).toDouble(),
    );
  }
}

class RelevanceReport {
  final bool isRelated;
  final List<SimilarSummary> similarSummaries;

  RelevanceReport({
    required this.isRelated,
    required this.similarSummaries,
  });

  factory RelevanceReport.fromJson(Map<String, dynamic> json) {
    return RelevanceReport(
      isRelated: json['is_related'] ?? false,
      similarSummaries: (json['similar_summaries'] as List?)
              ?.map((e) => SimilarSummary.fromJson(e))
              .toList() ??
          [],
    );
  }
}

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
  final RelevanceReport? relevanceReport;

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
    this.relevanceReport,
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

  Future<void> summarize(String url) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSummary: true,
    );

    try {
      final videoData = await _extractionService.fetchVideoData(url);

      // Note: the Python backend saves to DB in a background task — no client-side save needed.
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
          relevanceReport: videoData['relevance_report'] != null
              ? RelevanceReport.fromJson(videoData['relevance_report'])
              : null,
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
