import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
// 🔥 Adjust this import path if needed!
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
  
  // NOTE: Removed the initState fetch. The provider does it automatically now!

  Future<void> _launchYouTubeVideo() async {
    final Uri url = Uri.parse(widget.videoUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open YouTube link: ${widget.videoUrl}')),
        );
      }
    }
  }

  void _showFullText(BuildContext context, String sheetTitle, String content) {
    if (!widget.isViewed && widget.onViewed != null) {
      widget.onViewed!();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    sheetTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
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
    // 🔥 Watch the global state and check if this channel is in the Set
    final isSubscribed = ref.watch(subscriptionProvider).contains(widget.channelName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: widget.isViewed ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isViewed ? Colors.transparent : Colors.blue.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Thumbnail and Title Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.thumbnailUrl,
                    width: 100,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!widget.isViewed)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.channelName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 2. Dynamic Subscribe Button ──
            Row(
              children: [
                ElevatedButton.icon(
                  // 🔥 Tell the brain to toggle it
                  onPressed: () async {
                    try {
                      await ref.read(subscriptionProvider.notifier).toggleSubscription(widget.channelName);
                    } catch(e) {
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  icon: Icon(
                    isSubscribed ? Icons.check_circle : Icons.subscriptions, 
                    size: 18
                  ),
                  label: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubscribed ? Colors.grey[300] : Colors.red,
                    foregroundColor: isSubscribed ? Colors.black87 : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 3. Clickable Video URL Link ──
            InkWell(
              onTap: _launchYouTubeVideo,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.videoUrl,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 4. Summary Container ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showFullText(context, 'Full Summary', widget.summary),
                          child: const Text('View Full'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showFullText(context, 'Transcript', widget.fullTranscript),
                          child: const Text('View Transcript'),
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
    );
  }
}