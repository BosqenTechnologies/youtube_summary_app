import 'package:flutter/material.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/features/youtube_summary/presentation/screens/subscriptions_screen.dart';
import '../../data/services/database_service.dart';
import '../widgets/summary_result_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: AppColors.primaryRed),
        //   onPressed: () {}, 
        // ),
        centerTitle: true,
        title: const Text(
          'TubeSum',
          style: TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.primaryRed),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
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
                  color: AppColors.primaryRed,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _savedSummaries.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Vault',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Previously summarized insights.',
                              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SummaryResultCard(
        videoId: videoId ?? '',
        thumbnailUrl: thumbnailUrl,
        title: item['title'] ?? 'Unknown Title',
        channelName: item['channel_name'] ?? 'Unknown Channel',
        summary: item['summary'] ?? '',
        fullTranscript: item['transcript'] ?? '',
        videoUrl: item['video_url'] ?? '',
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