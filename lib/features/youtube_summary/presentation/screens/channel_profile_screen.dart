import 'package:flutter/material.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/features/youtube_summary/data/services/youtube_extraction_service.dart';

class ChannelProfileScreen extends StatefulWidget {
  final String channelName;

  const ChannelProfileScreen({
    super.key,
    required this.channelName,
  });

  @override
  State<ChannelProfileScreen> createState() => _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends State<ChannelProfileScreen> {
  final _service = YouTubeExtractionService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _service.fetchChannelProfile(widget.channelName);
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
        title: Text(
          widget.channelName,
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CREATOR PERSONA',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Text(
                          _profileData?['profile_summary'] ?? 'No profile generated yet.',
                          style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textDark),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'LATEST CONTENT FOCUS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      ...(_profileData?['last_3_summaries'] as List? ?? []).map((v) => _buildVideoCard(v)).toList(),

                      const SizedBox(height: 32),
                      
                      const Text(
                        'QUICK LINKS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Channel URL: ${_profileData?['channel_url'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 14, color: AppColors.textDark.withOpacity(0.8), height: 1.5),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVideoCard(dynamic video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.buttonGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video['title'] ?? 'Unknown Title',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            video['summary'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.textDark.withOpacity(0.7), height: 1.4),
          ),
        ],
      ),
    );
  }
}
