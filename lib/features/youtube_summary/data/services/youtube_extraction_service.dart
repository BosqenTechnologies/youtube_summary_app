import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeExtractionService {
  Future<Map<String, dynamic>> fetchVideoData(String url) async {
    // 1. Validate URL before sending to server
    if (!_isValidYouTubeUrl(url.trim())) {
      throw Exception(
        'Invalid YouTube URL.\n'
        'Please paste a link like:\n'
        'https://www.youtube.com/watch?v=XXXXXXXXXXX',
      );
    }

    try {
      // 2. Call our API passing the URL.
      final encodedUrl = Uri.encodeComponent(url.trim());
      final apiUrl = Uri.parse('http://127.0.0.1:8000/transcript?url=$encodedUrl');
      final response = await http.get(apiUrl);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch from Python API (Status ${response.statusCode}). Message: ${response.body}');
      }

      final data = jsonDecode(response.body);
      
      if (data['status'] == 'error') {
        throw Exception(data['message']);
      }

      // 3. Return data precisely as Supabase Database expects
      return {
        'video_id': data['video_id'],
        // 🔥 FIX: Added fallback to the original url just in case the API doesn't return it
        'video_url': data['video_url'] ?? url, 
        'title': data['title'],
        'channel_name': data['channel_name'],
        'transcript': data['transcript'],
        'summary': data['summary'],
      };
      
    } catch (e) {
      throw Exception('Extraction Error: $e');
    }
  }

  // ── Basic YouTube URL validator ──
  bool _isValidYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
  }
}