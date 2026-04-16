import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';

class SubscriptionNotifier extends StateNotifier<Map<String, bool>> {
  final DatabaseService _db = DatabaseService();

  SubscriptionNotifier() : super({});

  // Fetches the initial status from the DB without flickering
  Future<void> fetchStatus(String channelName) async {
    // If we already know the status, don't ask the DB again
    if (state.containsKey(channelName)) return; 

    final data = await _db.getSubscriptionStatus(channelName);
    final isSubscribed = data != null ? (data['is_subscribed'] ?? false) : false;
    
    // Update the global map
    state = { ...state, channelName: isSubscribed };
  }

  // Toggles the status instantly across the whole app
  Future<void> toggleSubscription(String channelName) async {
    final currentState = state[channelName] ?? false;
    final newState = !currentState;

    // Optimistic UI update: Instantly change it in the app so it feels snappy
    state = { ...state, channelName: newState };

    try {
      await _db.updateSubscription(
        channelName: channelName,
        isSubscribed: newState,
        notificationsEnabled: false,
      );
    } catch (e) {
      // If the DB fails, revert the color back
      state = { ...state, channelName: currentState };
    }
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, Map<String, bool>>((ref) {
  return SubscriptionNotifier();
});