import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeExtractionService {
  Future<Map<String, dynamic>> fetchVideoData(String url) async {
    if (!_isValidYouTubeUrl(url.trim())) {
      throw Exception(
        'Invalid YouTube URL.\nPlease paste a link like:\nhttps://www.youtube.com/watch?v=XXXXXXXXXXX',
      );
    }

    try {
      final encodedUrl = Uri.encodeComponent(url.trim());
      // Update this IP if your backend is hosted elsewhere
      final apiUrl = Uri.parse('http://127.0.0.1:8000/transcript?url=$encodedUrl');
      final response = await http.get(apiUrl);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch from Python API (Status ${response.statusCode}).');
      }

      final data = jsonDecode(response.body);
      
      if (data['status'] == 'error') {
        throw Exception(data['message']);
      }

      return {
        'video_id': data['video_id'],
        'video_url': data['video_url'] ?? url, 
        'title': data['title'],
        'channel_name': data['channel_name'],
        'channel_url': data['channel_url'],
        'channel_profile_summary': data['channel_profile_summary'],
        'previous_summaries': data['previous_summaries'],
        'transcript': data['transcript'],
        'summary': data['summary'],
      };
      
    } catch (e) {
      throw Exception('Extraction Error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchChannelProfile(String channelName) async {
    try {
      final encodedName = Uri.encodeComponent(channelName.trim());
    // To this:
      final apiUrl = Uri.parse('http://10.0.2.2:8000/channel-profile?channel_name=$encodedName');
      final response = await http.get(apiUrl);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch channel profile (Status ${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      if (data['status'] == 'error') {
        throw Exception(data['message']);
      }

      return data['data']; 
    } catch (e) {
      throw Exception('Channel Profile Error: $e');
    }
  }

  bool _isValidYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
  }
}
