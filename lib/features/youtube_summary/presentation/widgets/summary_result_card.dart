import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/full_summary_screen.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/channel_profile_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../state/subscription_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final isSubscribed = ref.watch(subscriptionProvider).contains(widget.channelName);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!widget.isViewed) 
            BoxShadow(color: AppColors.primaryRed.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
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
                    decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(6)),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                        style: const TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w700, 
                          color: AppColors.primaryRed, 
                          letterSpacing: 0.5,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(subscriptionProvider.notifier).toggleSubscription(widget.channelName),
                      child: Icon(
                        isSubscribed ? Icons.check_circle : Icons.add_circle_outline,
                        color: isSubscribed ? Colors.green : AppColors.textGrey,
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
                          backgroundColor: AppColors.primaryRed,
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
                          backgroundColor: AppColors.buttonGrey,
                          foregroundColor: AppColors.textDark,
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