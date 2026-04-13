import 'package:supabase_flutter/supabase_flutter.dart';

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
      // 2. Call your new Supabase Edge Function!
      final response = await Supabase.instance.client.functions.invoke(
        'get-transcript',
        body: {'url': url.trim()},
      );

      // 3. Extract the data
      final data = response.data as Map<String, dynamic>;

      // Check if the server sent back a specific error
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      // 4. Validate the response has all required fields
      final required = ['video_id', 'video_url', 'title', 'channel_name', 'transcript'];
      for (final key in required) {
        if (data[key] == null || data[key].toString().isEmpty) {
          throw Exception('Server returned incomplete data. Missing: $key');
        }
      }

      return data;
      
    } on FunctionException catch (e) {
      // Handles errors thrown directly by the Edge Function
      throw Exception('Server Error: ${e.details ?? e.reasonPhrase}');
    } catch (e) {
      // Handles network issues (like no internet)
      throw Exception('Failed to connect to server: $e');
    }
  }

  // ── Basic YouTube URL validator ──
  bool _isValidYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
  }
}