import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  // ── 1. Video Summary Methods ──
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
      if (e.code == '23505') {
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

  // ── 2. NEW: Subscription & Notification Methods ──
  
  /// Updates or inserts a channel's subscription/notification status
  Future<void> updateSubscription({
    required String channelName, 
    required bool isSubscribed, 
    required bool notificationsEnabled
  }) async {
    try {
      await supabase.from('channel_subscriptions').upsert({
        'channel_name': channelName,
        'is_subscribed': isSubscribed,
        'notifications_enabled': notificationsEnabled,
      });
      print('✅ Subscription updated for $channelName');
    } catch (e) {
      print('❌ Error updating subscription: $e');
      rethrow;
    }
  }

  /// Fetches the current status for a specific channel
  Future<Map<String, dynamic>?> getSubscriptionStatus(String channelName) async {
    try {
      final response = await supabase
          .from('channel_subscriptions')
          .select()
          .eq('channel_name', channelName)
          .maybeSingle(); // Returns null if not found
      return response;
    } catch (e) {
      print('❌ Error fetching subscription status: $e');
      return null;
    }
  }

  // 🔥 NEW: Mark a video as viewed
  Future<void> markAsViewed(String videoId) async {
    try {
      await supabase
          .from('youtube_summaries')
          .update({'is_viewed': true})
          .eq('video_id', videoId);
    } catch (e) {
      print('❌ Error marking as viewed: $e');
    }
  }
}