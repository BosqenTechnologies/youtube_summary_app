import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  Future<void> saveVideoData(Map<String, dynamic> videoData) async {
    try {
      await supabase.from('youtube_summaries').insert({
        'video_id': videoData['video_id'],
        'video_url': videoData['video_url'],
        'title': videoData['title'],
        'channel_name': videoData['channel_name'],
        'transcript': videoData['transcript'],
        'summary': videoData['summary'],
      });
      print('✅ Saved to Supabase successfully!');
    } on PostgrestException catch (e) {
      // ✅ Catch Supabase-specific errors properly
      if (e.code == '23505') {
        // Postgres duplicate key violation code
        print('⚠️ Video already exists in the database. Skipping insert.');
      } else {
        print('❌ Supabase error [${e.code}]: ${e.message}');
        rethrow;
      }
    } catch (e) {
      print('❌ Unexpected error saving to Supabase: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedSummaries() async {
    try {
      final response = await supabase
          .from('youtube_summaries')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Unexpected error fetching from Supabase: $e');
      return [];
    }
  }
}