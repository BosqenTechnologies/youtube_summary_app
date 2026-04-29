import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/theme/theme_provider.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/channel_screen.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchSummaries();
  }

  Future<void> _fetchSummaries() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final summaries = await _databaseService.getSavedSummaries();
      if (mounted) {
        setState(() {
          _savedSummaries = summaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SummaryState>(summaryProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false && next.summary != null) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _fetchSummaries();
        });
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- 4-Color System Setup ---
    final primaryColor = isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final primaryText = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText = isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

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
            icon: Icon(Icons.notifications, color: primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChannelsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: primaryColor,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _savedSummaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_hasError) ...[
                        Icon(Icons.wifi_off_rounded, size: 64, color: secondaryText),
                        const SizedBox(height: AppDimensions.spacingNormal),
                        Text(
                          'Could not load vault.',
                          style: TextStyle(color: secondaryText, fontSize: AppDimensions.fontNormal),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        TextButton.icon(
                          onPressed: _fetchSummaries,
                          icon: Icon(Icons.refresh, color: primaryColor),
                          label: Text('Retry', style: TextStyle(color: primaryColor)),
                        ),
                      ] else ...[
                        Icon(Icons.inventory_2_outlined, size: 64, color: secondaryText),
                        const SizedBox(height: AppDimensions.spacingNormal),
                        Text(
                          'No summaries in vault yet.',
                          style: TextStyle(color: secondaryText, fontSize: AppDimensions.fontNormal),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSummaries,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium, 
                      vertical: AppDimensions.paddingNormal,
                    ),
                    itemCount: _savedSummaries.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.yourVault,
                              style: TextStyle(
                                fontSize: AppDimensions.fontTitleLarge, 
                                fontWeight: FontWeight.bold, 
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingSmall / 2),
                            Text(
                              AppStrings.vaultSubtitle,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSmall, 
                                color: secondaryText,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingLarge),
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
        debugPrint('Error parsing relevance_report: $e');
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
        debugPrint('Error parsing previous_summaries: $e');
      }
    }

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
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
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