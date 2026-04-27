import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final secondaryColor = onSurface.withOpacity(0.5);
    final fillColor = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text(
          widget.channelName,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
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
                      Text(
                        'CREATOR PERSONA',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                        ),
                        child: Text(
                          _profileData?['profile_summary'] ?? 'No profile generated yet.',
                          style: TextStyle(fontSize: 16, height: 1.6, color: onSurface),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'LATEST CONTENT FOCUS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      ...(_profileData?['last_3_summaries'] as List? ?? []).map((v) => _buildVideoCard(v, cardColor, fillColor, onSurface)).toList(),

                      const SizedBox(height: 32),
                      
                      Text(
                        'QUICK LINKS',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: secondaryColor, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Channel URL: ${_profileData?['channel_url'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.8), height: 1.5),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVideoCard(dynamic video, Color cardColor, Color borderColor, Color onSurface) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video['title'] ?? 'Unknown Title',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            video['summary'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.7), height: 1.4),
          ),
        ],
      ),
    );
  }
}
