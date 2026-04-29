// lib/features/youtube_summary/presentation/state/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';
import '../../../../core/notifications/notification_helper.dart';

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, Set<String>>(
  (ref) => SubscriptionNotifier(DatabaseService()),
);

class SubscriptionNotifier extends StateNotifier<Set<String>> {
  final DatabaseService _db;

  SubscriptionNotifier(this._db) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final subs = await _db.getAllSubscriptions();
    final subscribed = <String>{};

    for (final sub in subs) {
      final name = sub['channel_name'] as String? ?? '';
      final isSubscribed = sub['is_subscribed'] as bool? ?? false;
      if (isSubscribed && name.isNotEmpty) {
        subscribed.add(name);
      }
    }

    state = subscribed;

    await NotificationHelper.restoreTopicsForUser(subs);
  }

  Future<void> refresh() => _load();

  // ✨ UPDATED: Now accepts an optional channelUrl
  Future<void> toggleSubscription(String channelName, {String? channelUrl}) async {
    final isCurrentlySubscribed = state.contains(channelName);
    final newSubscribed = !isCurrentlySubscribed;

    final current = await _db.getSubscriptionStatus(channelName);
    final currentNotif = current?['notifications_enabled'] as bool? ?? true;

    await _db.updateSubscription(
      channelName: channelName,
      isSubscribed: newSubscribed,
      notificationsEnabled: newSubscribed ? currentNotif : false,
      channelUrl: channelUrl, // ✨ Pass the URL down to the database
    );

    if (newSubscribed) {
      state = {...state, channelName};
      if (currentNotif) {
        await NotificationHelper.subscribeToChannel(channelName);
      }
    } else {
      state = state.where((c) => c != channelName).toSet();
      await NotificationHelper.unsubscribeFromChannel(channelName);
    }
  }

  Future<void> addChannel({
    required String channelName,
    required String channelUrl,
    required bool notificationsEnabled,
  }) async {
    await _db.updateSubscription(
      channelName: channelName,
      isSubscribed: true,
      notificationsEnabled: notificationsEnabled,
      channelUrl: channelUrl,
    );

    state = {...state, channelName};

    if (notificationsEnabled) {
      await NotificationHelper.subscribeToChannel(channelName);
    }
  }

  Future<void> setNotifications({
    required String channelName,
    required bool enabled,
    String? channelUrl,
  }) async {
    await _db.updateSubscription(
      channelName: channelName,
      isSubscribed: true,
      notificationsEnabled: enabled,
      channelUrl: channelUrl,
    );

    if (enabled) {
      await NotificationHelper.subscribeToChannel(channelName);
    } else {
      await NotificationHelper.unsubscribeFromChannel(channelName);
    }
  }

  Future<void> removeChannel(String channelName) async {
    await _db.deleteSubscription(channelName);
    await NotificationHelper.unsubscribeFromChannel(channelName);
    state = state.where((c) => c != channelName).toSet();
  }
}