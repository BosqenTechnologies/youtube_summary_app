import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/full_summary_screen.dart';
// AppColors no longer used here — rely on Theme
import '../state/subscription_provider.dart';

class SummaryResultCard extends ConsumerStatefulWidget {
  final String videoId;
  final String thumbnailUrl;
  final String title;
  final String channelName;
  final String summary;
  final String fullTranscript;
  final String videoUrl;
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
    // Navigates to the brand new Full Summary View
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubscribed = ref.watch(subscriptionProvider).contains(widget.channelName);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!widget.isViewed) // Highlight new items
            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Full Width Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                ),
              ),
              if (!widget.isViewed)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
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
                // 2. Title
                Text(
                  widget.title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // 3. Channel Name & Subscribe (Embedded cleanly)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.channelName.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w600) ?? const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    InkWell(
                      onTap: () => ref.read(subscriptionProvider.notifier).toggleSubscription(widget.channelName),
                      child: Icon(
                        isSubscribed ? Icons.check_circle : Icons.add_circle_outline,
                        color: isSubscribed ? Colors.green : theme.textTheme.labelSmall?.color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openFullSummary(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
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
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.colorScheme.onSurface,
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
    );
  }
}