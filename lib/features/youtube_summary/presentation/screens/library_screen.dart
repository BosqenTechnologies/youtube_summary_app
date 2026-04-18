import 'package:flutter/material.dart';
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
    setState(() {
      _isLoading = true;
    });
    
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
      appBar: AppBar(
        title: const Text('TubeSum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.red),
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
          ? const Center(child: CircularProgressIndicator())
          : _savedSummaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No summaries yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSummaries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedSummaries.length,
                    itemBuilder: (context, index) {
                      final item = _savedSummaries[index];
                      final videoId = item['video_id'];
                      final thumbnailUrl = item['thumbnail_url'] ?? 
                          (videoId != null ? 'https://img.youtube.com/vi/$videoId/0.jpg' : '');
                          
                      // 🔥 Fetch status, default to true for old data so it doesn't all glow
                      final isViewed = item['is_viewed'] ?? true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SummaryResultCard(
                          videoId: videoId ?? '', // 🔥 Pass video ID
                          thumbnailUrl: thumbnailUrl,
                          title: item['title'] ?? 'Unknown Title',
                          channelName: item['channel_name'] ?? 'Unknown Channel',
                          summary: item['summary'] ?? '',
                          fullTranscript: item['transcript'] ?? '',
                          videoUrl: item['video_url'] ?? '',
                          isViewed: isViewed, // 🔥 Pass status
                          onViewed: () async {
                            // 🔥 When user clicks view, update DB and refresh UI
                            if (videoId != null) {
                              await _databaseService.markAsViewed(videoId);
                              _fetchSummaries();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}