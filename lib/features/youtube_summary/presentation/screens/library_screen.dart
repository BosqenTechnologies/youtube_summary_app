import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_summary_app/core/theme/theme_provider.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/subscriptions_screen.dart';
import '../../data/services/database_service.dart';
import '../state/summary_provider.dart';
import '../widgets/summary_result_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _savedSummaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummaries();
  }

  Future<void> _fetchSummaries() async {
    setState(() => _isLoading = true);
    final summaries = await _databaseService.getSavedSummaries();
    if (mounted) {
      setState(() {
        _savedSummaries = summaries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: AppColors.primaryRed),
        //   onPressed: () {}, 
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
          IconButton(
            icon: Icon(Icons.notifications, color: theme.colorScheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              // Change icon based on current theme
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              // 🔥 Tell the provider to toggle the theme
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _savedSummaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No summaries in vault yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _fetchSummaries,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _savedSummaries.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Vault',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Previously summarized insights.',
                              style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                            ),
                            const SizedBox(height: 24),
                            _buildListItem(index),
                          ],
                        );
                      }
                      return _buildListItem(index);
                    },
                  ),
                ),
    );
  }

  Widget _buildListItem(int index) {
    final item = _savedSummaries[index];
    final videoId = item['video_id'];
    final thumbnailUrl = item['thumbnail_url'] ?? (videoId != null ? 'https://img.youtube.com/vi/$videoId/0.jpg' : '');
    final isViewed = item['is_viewed'] ?? true;

    // Robust extraction for JSON/Complex fields
    dynamic rawRelevance = item['relevance_report'];
    RelevanceReport? relevanceReport;
    if (rawRelevance != null) {
      try {
        if (rawRelevance is String) {
          relevanceReport = RelevanceReport.fromJson(jsonDecode(rawRelevance));
        } else if (rawRelevance is Map) {
          relevanceReport = RelevanceReport.fromJson(Map<String, dynamic>.from(rawRelevance));
        }
      } catch (e) {
        print('Error parsing relevance_report: $e');
      }
    }

    dynamic rawPrevious = item['previous_summaries'];
    List<String> previousSummaries = [];
    if (rawPrevious != null) {
      try {
        if (rawPrevious is String) {
          previousSummaries = List<String>.from(jsonDecode(rawPrevious));
        } else if (rawPrevious is List) {
          previousSummaries = List<String>.from(rawPrevious);
        }
      } catch (e) {
        print('Error parsing previous_summaries: $e');
      }
    }

    // Handle potential corrupted summary (Map instead of String)
    String summaryText = '';
    dynamic rawSummary = item['summary'];
    if (rawSummary != null) {
      if (rawSummary is String) {
        summaryText = rawSummary;
      } else if (rawSummary is Map) {
        summaryText = rawSummary['summary'] ?? rawSummary['text'] ?? rawSummary.toString();
      } else {
        summaryText = rawSummary.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SummaryResultCard(
        videoId: videoId ?? '',
        thumbnailUrl: thumbnailUrl,
        title: item['title'] ?? 'Unknown Title',
        channelName: item['channel_name'] ?? 'Unknown Channel',
        summary: summaryText,
        fullTranscript: item['transcript'] ?? '',
        videoUrl: item['video_url'] ?? '',
        channelUrl: item['channel_url'],
        channelProfileSummary: item['channel_profile_summary'],
        previousSummaries: previousSummaries,
        relevanceReport: relevanceReport,
        isViewed: isViewed,
        onViewed: () async {
          if (videoId != null) {
            await _databaseService.markAsViewed(videoId);
            _fetchSummaries();
          }
        },
      ),
    );
  }
}