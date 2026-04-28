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
        'channel_url': videoData['channel_url'],
        'channel_profile_summary': videoData['channel_profile_summary'],
        'previous_summaries': videoData['previous_summaries'],
        'relevance_report': videoData['relevance_report'],
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
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10), onTimeout: () {
            print('⏱️ getSavedSummaries timed out');
            return [];
          });

      final list = List<Map<String, dynamic>>.from(response);
      // Only show rows with a real summary — filters out any error/partial records
      return list.where((row) => row['summary'] != null && row['summary'].toString().trim().isNotEmpty).toList();
    } catch (e) {
      print('❌ Unexpected error fetching from Supabase: $e');
      return [];
    }
  }

  /// Fetch a single saved summary by its video_id (for Related Intelligence navigation).
  Future<Map<String, dynamic>?> getSummaryByVideoId(String videoId) async {
    try {
      final response = await supabase
          .from('youtube_summaries')
          .select()
          .eq('video_id', videoId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Error fetching summary by videoId: $e');
      return null;
    }
  }

  // ── 2. Subscription & Notification Methods ──

  /// Upserts a channel subscription row and ensures the channel exists in the main table.
  Future<void> updateSubscription({
    required String channelName,
    required bool isSubscribed,
    required bool notificationsEnabled,
    String? channelUrl, 
  }) async {
    try {
      // 🔥 CRITICAL FIX: Ensure the channel exists in the main 'channels' table first!
      await supabase.from('channels').upsert({
        'channel_name': channelName,
        if (channelUrl != null && channelUrl.isNotEmpty) 'channel_url': channelUrl,
      }, onConflict: 'channel_name');

      // Then update the Python API table preferences
      await supabase.from('channel_subscriptions').upsert({
        'channel_name': channelName,
        'is_subscribed': isSubscribed,
        'notifications_enabled': notificationsEnabled,
        if (channelUrl != null && channelUrl.isNotEmpty) 'channel_url': channelUrl,
      });
      print('✅ Subscription updated for $channelName');
    } catch (e) {
      print('❌ Error updating subscription: $e');
      rethrow;
    }
  }

  /// Fetches the current subscription status for ONE specific channel.
  Future<Map<String, dynamic>?> getSubscriptionStatus(
      String channelName) async {
    try {
      final response = await supabase
          .from('channel_subscriptions')
          .select()
          .eq('channel_name', channelName)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Error fetching subscription status: $e');
      return null;
    }
  }

  // 🔥 NEW: Fetch ALL channel subscriptions (for the Channels screen)
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      final response = await supabase
          .from('channel_subscriptions')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching all subscriptions: $e');
      return [];
    }
  }

  // 🔥 NEW: Remove a channel subscription entirely
  Future<void> deleteSubscription(String channelName) async {
    try {
      await supabase
          .from('channel_subscriptions')
          .delete()
          .eq('channel_name', channelName);
      print('🗑️ Deleted subscription for $channelName');
    } catch (e) {
      print('❌ Error deleting subscription: $e');
      rethrow;
    }
  }

  // Mark a video as viewed
  Future<void> markAsViewed(String videoId) async {
    try {
      await supabase
          .from('youtube_summaries')
          .update({'is_viewed': true}).eq('video_id', videoId);
    } catch (e) {
      print('❌ Error marking as viewed: $e');
    }
  }
}