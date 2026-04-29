// lib/features/youtube_summary/presentation/state/subscription_provider.dart
//
// Riverpod state for the current user's channel subscriptions.
// Backed by the `channel_subscriptions` Supabase table (per-user via RLS).
// Also manages Firebase topic subscription/unsubscription so notifications
// follow the user's per-channel preference automatically.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';
import '../../../../core/notifications/notification_helper.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

/// Exposes the SET of channel names the current user is subscribed to.
/// Use `ref.watch(subscriptionProvider).contains(channelName)` in UI.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, Set<String>>(
  (ref) => SubscriptionNotifier(DatabaseService()),
);

// ── Notifier ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<Set<String>> {
  final DatabaseService _db;

  SubscriptionNotifier(this._db) : super(const {}) {
    _load();
  }

  // ── Internal load & FCM restore ───────────────────────────────────────────

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

    // Restore Firebase topic subscriptions for this device after login /
    // app restart so the user never misses a notification.
    await NotificationHelper.restoreTopicsForUser(subs);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Force a fresh load from Supabase (e.g. after navigating back from
  /// ChannelsScreen).
  Future<void> refresh() => _load();

  /// Toggle subscribed state for [channelName].
  /// If subscribing, inherits existing notification preference (defaults to
  /// enabled for new channels).
  /// If unsubscribing, always disables notifications and unsubscribes FCM topic.
// ✨ UPDATED: Added {String? channelUrl} to the parameters
  Future<void> toggleSubscription(String channelName, {String? channelUrl}) async {
    final isCurrentlySubscribed = state.contains(channelName);
    final newSubscribed = !isCurrentlySubscribed;

    // Get current notification preference
    final current = await _db.getSubscriptionStatus(channelName);
    final currentNotif = current?['notifications_enabled'] as bool? ?? true;

    await _db.updateSubscription(
      channelName: channelName,
      isSubscribed: newSubscribed,
      notificationsEnabled: newSubscribed ? currentNotif : false,
      channelUrl: channelUrl, // Pass the URL down to the database
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

  /// Full add-channel flow: saves to DB, updates local state, subscribes FCM.
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

  /// Update notification preference for a channel.
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

  /// Remove channel entirely: deletes from DB, removes from state, unsubs FCM.
  Future<void> removeChannel(String channelName) async {
    await _db.deleteSubscription(channelName);
    await NotificationHelper.unsubscribeFromChannel(channelName);
    state = state.where((c) => c != channelName).toSet();
  }
}