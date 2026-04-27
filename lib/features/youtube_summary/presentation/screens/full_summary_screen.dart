import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_summary_app/features/youtube_summary/data/services/database_service.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/state/summary_provider.dart';


class FullSummaryScreen extends StatefulWidget {
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String content;
  final String videoUrl;
  final bool isTranscript;
  final String? channelProfileSummary;
  final List<String> previousSummaries;
  final RelevanceReport? relevanceReport;

  const FullSummaryScreen({
    super.key,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.content,
    required this.videoUrl,
    required this.isTranscript,
    this.channelProfileSummary,
    this.previousSummaries = const [],
    this.relevanceReport,
  });

  @override
  State<FullSummaryScreen> createState() => _FullSummaryScreenState();
}

class _FullSummaryScreenState extends State<FullSummaryScreen> {
  final _databaseService = DatabaseService();

  Future<void> _launchYouTubeVideo(BuildContext context) async {
    final Uri url = Uri.parse(widget.videoUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open YouTube link: ${widget.videoUrl}')),
        );
      }
    }
  }

  void _copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  /// Tap on a related video: try to open its vault full summary, else open YouTube.
  Future<void> _openRelatedVideo(BuildContext context, SimilarSummary similar) async {
    final theme = Theme.of(context);
    // Show a brief loading indicator
    final messenger = ScaffoldMessenger.of(context);
    final loadingSnack = SnackBar(
      content: Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 12),
          Text('Loading vault summary…'),
        ],
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: theme.colorScheme.primary,
    );
    messenger.showSnackBar(loadingSnack);

    final vaultData = await _databaseService.getSummaryByVideoId(similar.videoId);
    messenger.hideCurrentSnackBar();

    if (!context.mounted) return;

    if (vaultData != null) {
      // Parse the saved data and open a full summary screen for the related video
      final videoId = vaultData['video_id'] ?? similar.videoId;
      final thumbnailUrl =
          vaultData['thumbnail_url'] ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

      // Parse relevance report if present
      RelevanceReport? relReport;
      dynamic rawRelevance = vaultData['relevance_report'];
      if (rawRelevance != null) {
        try {
          if (rawRelevance is String) {
            relReport = RelevanceReport.fromJson(jsonDecode(rawRelevance));
          } else if (rawRelevance is Map) {
            relReport = RelevanceReport.fromJson(Map<String, dynamic>.from(rawRelevance));
          }
        } catch (_) {}
      }

      // Parse previous summaries
      List<String> prevSummaries = [];
      dynamic rawPrev = vaultData['previous_summaries'];
      if (rawPrev != null) {
        try {
          if (rawPrev is String) {
            prevSummaries = List<String>.from(jsonDecode(rawPrev));
          } else if (rawPrev is List) {
            prevSummaries = List<String>.from(rawPrev);
          }
        } catch (_) {}
      }

      // Parse summary text
      String summaryText = similar.summary;
      dynamic rawSummary = vaultData['summary'];
      if (rawSummary != null) {
        if (rawSummary is String) {
          summaryText = rawSummary;
        } else if (rawSummary is Map) {
          summaryText = rawSummary['summary'] ?? rawSummary['text'] ?? summaryText;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullSummaryScreen(
            title: vaultData['title'] ?? similar.title,
            channelName: vaultData['channel_name'] ?? similar.channelName,
            thumbnailUrl: thumbnailUrl,
            content: summaryText,
            videoUrl: vaultData['video_url'] ?? 'https://www.youtube.com/watch?v=$videoId',
            isTranscript: false,
            channelProfileSummary: vaultData['channel_profile_summary'],
            previousSummaries: prevSummaries,
            relevanceReport: relReport,
          ),
        ),
      );
    } else {
      // Not in vault yet — open on YouTube
      await launchUrl(
        Uri.parse('https://www.youtube.com/watch?v=${similar.videoId}'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final secondaryColor = onSurface.withOpacity(0.5);
    final fillColor = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest;
    final surfaceHigh = theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.isTranscript ? 'Full Transcript' : 'Full Summary',
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.thumbnailUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: surfaceHigh),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.channelName.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor, letterSpacing: 1.0),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        if (!widget.isTranscript)
                          Container(
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: primary, width: 3)),
                            ),
                            child: Text(
                              'Insights generated by TubeSum AI.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        Text(
                          widget.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: onSurface.withOpacity(0.85),
                            height: 1.6,
                          ),
                        ),

                        if (!widget.isTranscript && widget.channelProfileSummary != null && widget.channelProfileSummary!.isNotEmpty) ...[
                          const SizedBox(height: 40),
                          Text(
                            'ABOUT THE CREATOR',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.channelProfileSummary!,
                            style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.8), height: 1.5),
                          ),
                        ],

                        if (!widget.isTranscript && widget.previousSummaries.isNotEmpty) ...[
                          const SizedBox(height: 40),
                          Text(
                            'PREVIOUS CONTEXT',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          ...widget.previousSummaries.map((summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: fillColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "• $summary",
                                style: TextStyle(fontSize: 13, color: onSurface, fontStyle: FontStyle.italic),
                              ),
                            ),
                          )).toList(),
                        ],

                        if (!widget.isTranscript) ...[
                          const SizedBox(height: 40),
                          Text(
                            'RELATED INTELLIGENCE',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          if (widget.relevanceReport != null && widget.relevanceReport!.isRelated)
                            ...widget.relevanceReport!.similarSummaries.map((similar) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openRelatedVideo(context, similar),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: fillColor),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5, offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: 'https://i.ytimg.com/vi/${similar.videoId}/hqdefault.jpg',
                                          width: 100,
                                          height: 66,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            width: 100,
                                            height: 66,
                                            color: surfaceHigh,
                                            child: const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${(similar.similarity * 100).toStringAsFixed(0)}% Match',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'In Vault',
                                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primary),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              similar.title,
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: onSurface),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              similar.channelName.toUpperCase(),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryColor),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              similar.summary,
                                              style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.7), height: 1.4),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.open_in_new, size: 12, color: primary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Tap to view full summary',
                                                  style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )).toList()
                          else
                            Container(
                              padding: const EdgeInsets.all(20),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: fillColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: fillColor),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.hub_outlined, color: secondaryColor, size: 32),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No related content discovered yet.',
                                    style: TextStyle(color: secondaryColor, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try summarizing more videos to build your knowledge map.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: secondaryColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _copyText(context),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy Text'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fillColor,
                            foregroundColor: onSurface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {}, 
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fillColor,
                            foregroundColor: onSurface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchYouTubeVideo(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Watch Original', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}