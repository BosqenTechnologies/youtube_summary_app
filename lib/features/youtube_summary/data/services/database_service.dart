import 'package:supabase_flutter/supabase_flutter.dart';

/// Central data-access layer for TubeSum.
/// Every subscription read/write is scoped to the currently signed-in user.
/// RLS on the `channel_subscriptions` table enforces this server-side as well.
class DatabaseService {
  final supabase = Supabase.instance.client;

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Returns the current user's UUID, or null if not signed in.
  String? get _uid => supabase.auth.currentUser?.id;

  // ── 1. Video Summary Methods ─────────────────────────────────────────────

  Future<void> saveVideoData(Map<String, dynamic> videoData) async {
    try {
      await supabase.from('youtube_summaries').insert({
        'video_id':               videoData['video_id'],
        'video_url':              videoData['video_url'],
        'title':                  videoData['title'],
        'channel_name':           videoData['channel_name'],
        'transcript':             videoData['transcript'],
        'summary':                videoData['summary'],
        'channel_url':            videoData['channel_url'],
        'channel_profile_summary':videoData['channel_profile_summary'],
        'previous_summaries':     videoData['previous_summaries'],
        'relevance_report':       videoData['relevance_report'],
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
      return list
          .where((row) =>
              row['summary'] != null &&
              row['summary'].toString().trim().isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ Unexpected error fetching from Supabase: $e');
      return [];
    }
  }

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

  // ── 2. Per-User Subscription Methods ─────────────────────────────────────
  //
  // Every method below SCOPES itself to the current user.
  // RLS on `channel_subscriptions` provides a server-side second layer of
  // protection — even if the client sends the wrong user_id, Supabase rejects
  // the row.

  /// Upsert one subscription row for the current user.
  /// Also ensures the channel exists in the global `channels` registry.
  Future<void> updateSubscription({
    required String channelName,
    required bool isSubscribed,
    required bool notificationsEnabled,
    String? channelUrl,
  }) async {
    final uid = _uid;
    if (uid == null) {
      print('❌ updateSubscription: no signed-in user');
      return;
    }

    try {
      // Keep the global channels registry up-to-date
      await supabase.from('channels').upsert({
        'channel_name': channelName,
        if (channelUrl != null && channelUrl.isNotEmpty)
          'channel_url': channelUrl,
      }, onConflict: 'channel_name');

      // Per-user subscription row
      // onConflict targets (user_id, channel_name) — see UNIQUE constraint
      await supabase.from('channel_subscriptions').upsert({
        'user_id':              uid,
        'channel_name':         channelName,
        'is_subscribed':        isSubscribed,
        'notifications_enabled': notificationsEnabled,
        if (channelUrl != null && channelUrl.isNotEmpty)
          'channel_url': channelUrl,
      }, onConflict: 'user_id,channel_name');

      print('✅ Subscription updated — channel: $channelName | uid: $uid');
    } catch (e) {
      print('❌ Error updating subscription: $e');
      rethrow;
    }
  }

  /// Fetch subscription status for ONE channel for the current user.
  Future<Map<String, dynamic>?> getSubscriptionStatus(
      String channelName) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final response = await supabase
          .from('channel_subscriptions')
          .select()
          .eq('user_id', uid)
          .eq('channel_name', channelName)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Error fetching subscription status: $e');
      return null;
    }
  }

  /// Fetch ALL subscription rows for the current user.
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final response = await supabase
          .from('channel_subscriptions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching all subscriptions: $e');
      return [];
    }
  }

  /// Permanently delete a subscription row for the current user.
  Future<void> deleteSubscription(String channelName) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await supabase
          .from('channel_subscriptions')
          .delete()
          .eq('user_id', uid)
          .eq('channel_name', channelName);
      print('🗑️ Deleted subscription — channel: $channelName | uid: $uid');
    } catch (e) {
      print('❌ Error deleting subscription: $e');
      rethrow;
    }
  }

  // ── 3. Video viewed state ─────────────────────────────────────────────────

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