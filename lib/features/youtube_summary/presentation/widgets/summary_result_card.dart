import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/full_summary_screen.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/channel_profile_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../state/subscription_provider.dart';
import '../state/summary_provider.dart';

class SummaryResultCard extends ConsumerStatefulWidget {
  final String videoId;
  final String thumbnailUrl;
  final String title;
  final String channelName;
  final String summary;
  final String fullTranscript;
  final String videoUrl;
  final String? channelUrl;
  final String? channelProfileSummary;
  final List<String> previousSummaries;
  final RelevanceReport? relevanceReport;
  final bool isViewed;
  final VoidCallback? onViewed;

  const SummaryResultCard({
    super.key,
    required this.videoId,
    required this.thumbnailUrl,
    required this.title,
    required this.channelName,
    required this.summary,
    required this.fullTranscript,
    required this.videoUrl,
    this.channelUrl,
    this.channelProfileSummary,
    this.previousSummaries = const [],
    this.relevanceReport,
    this.isViewed = true,
    this.onViewed,
  });

  @override
  ConsumerState<SummaryResultCard> createState() => _SummaryResultCardState();
}

class _SummaryResultCardState extends ConsumerState<SummaryResultCard> {

  void _openFullSummary(BuildContext context) {
    if (!widget.isViewed && widget.onViewed != null) {
      widget.onViewed!();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullSummaryScreen(
          title: widget.title,
          channelName: widget.channelName,
          thumbnailUrl: widget.thumbnailUrl,
          content: widget.summary,
          videoUrl: widget.videoUrl,
          isTranscript: false,
          channelProfileSummary: widget.channelProfileSummary,
          previousSummaries: widget.previousSummaries,
          relevanceReport: widget.relevanceReport,
        ),
      ),
    );
  }

  void _openTranscript(BuildContext context) {
    if (!widget.isViewed && widget.onViewed != null) {
      widget.onViewed!();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullSummaryScreen(
          title: widget.title,
          channelName: widget.channelName,
          thumbnailUrl: widget.thumbnailUrl,
          content: widget.fullTranscript,
          videoUrl: widget.videoUrl,
          isTranscript: true,
        ),
      ),
    );
  }

  void _openChannelProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelProfileScreen(
          channelName: widget.channelName,
        ),
      ),
    );
  }

  void _showTranscriptBottomSheet(BuildContext context, SimilarSummary similar) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final fillColor = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: 'https://i.ytimg.com/vi/${similar.videoId}/hqdefault.jpg',
                      width: 60,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 40,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.error, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transcript: ${similar.title}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: onSurface), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(height: 1, color: secondaryColor.withOpacity(0.2)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SUMMARY',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      similar.summary,
                      style: TextStyle(fontSize: 15, color: onSurface, height: 1.6, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'FULL TRANSCRIPT',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      similar.transcript.isNotEmpty ? similar.transcript : "No transcript available for this video.",
                      style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.8), height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = ref.watch(subscriptionProvider).contains(widget.channelName);
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final secondaryColor = onSurface.withOpacity(0.5);
    final fillColor = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!widget.isViewed) 
                BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: widget.thumbnailUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: theme.colorScheme.surfaceContainerHighest),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.error, color: secondaryColor),
                      ),
                    ),
                  ),
                  if (!widget.isViewed)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _openChannelProfile(context),
                          child: Text(
                            widget.channelName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w700, 
                              color: primary, 
                              letterSpacing: 0.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => ref.read(subscriptionProvider.notifier).toggleSubscription(widget.channelName),
                          child: Icon(
                            isSubscribed ? Icons.check_circle : Icons.add_circle_outline,
                            color: isSubscribed ? Colors.green : secondaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openFullSummary(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 6),
                                Text('View Full', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openTranscript(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: fillColor,
                              foregroundColor: onSurface,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.notes, size: 18),
                                SizedBox(width: 6),
                                Text('Transcript', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // RELATED CONTENT OUTSIDE BELOW
        if (widget.relevanceReport != null && widget.relevanceReport!.isRelated) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fillColor.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_outlined, size: 14, color: secondaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'RELATED INTELLIGENCE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...widget.relevanceReport!.similarSummaries.take(2).map((similar) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => _showTranscriptBottomSheet(context, similar),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: fillColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: 'https://i.ytimg.com/vi/${similar.videoId}/hqdefault.jpg',
                              width: 48,
                              height: 32,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                width: 48,
                                height: 32,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_not_supported, size: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  similar.title,
                                  style: TextStyle(fontSize: 11, color: onSurface, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Tap to view related transcript",
                                  style: TextStyle(fontSize: 9, color: secondaryColor),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: secondaryColor),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}