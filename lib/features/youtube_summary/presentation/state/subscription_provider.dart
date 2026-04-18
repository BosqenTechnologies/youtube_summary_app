import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Provides a Set of subscribed channel NAMES (e.g., {'Money Pechu', 'Another Channel'})
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, Set<String>>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<Set<String>> {
  SubscriptionNotifier() : super({}) {
    _loadSubscriptions(); // Auto-load on app start
  }

  final supabase = Supabase.instance.client;

  Future<void> _loadSubscriptions() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Get the IDs this user is subscribed to
      final subsData = await supabase.from('user_subscriptions').select('channel_id').eq('user_id', userId);
      if (subsData.isEmpty) return;
      
      final subIds = subsData.map((e) => e['channel_id']).toList();

      // 2. Look up the names for those IDs so the UI can read them easily
      final channelsData = await supabase.from('channels').select('channel_name').inFilter('id', subIds);
      state = channelsData.map((e) => e['channel_name'].toString()).toSet();
    } catch (e) {
      print("Error loading subscriptions: $e");
    }
  }

  Future<void> toggleSubscription(String channelName) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Please log in to subscribe");

    final safeTopicName = 'channel_${channelName.replaceAll(' ', '')}';
    final isSubscribed = state.contains(channelName);

    // Optimistic UI Update: Instantly change the button color in the app
    if (isSubscribed) {
      state = {...state}..remove(channelName);
    } else {
      state = {...state}..add(channelName);
    }

    try {
      // Look up the channel ID from the database using the name
      final channelResp = await supabase.from('channels').select('id').eq('channel_name', channelName).single();
      final channelId = channelResp['id'];

      if (isSubscribed) {
        // UNSUBSCRIBE
        await supabase.from('user_subscriptions').delete().match({'user_id': userId, 'channel_id': channelId});
        await FirebaseMessaging.instance.unsubscribeFromTopic(safeTopicName);
      } else {
        // SUBSCRIBE
        await supabase.from('user_subscriptions').insert({'user_id': userId, 'channel_id': channelId});
        await FirebaseMessaging.instance.subscribeToTopic(safeTopicName);
      }
    } catch (e) {
      // If the database fails, revert the button back to its previous state
      if (isSubscribed) {
        state = {...state}..add(channelName);
      } else {
        state = {...state}..remove(channelName);
      }
      rethrow; 
    }
  }
}