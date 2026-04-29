// lib/core/notifications/notification_helper.dart
//
// Handles Firebase Cloud Messaging topic subscription/unsubscription.
// Supported platforms  : Android, iOS, Web
// Unsupported platforms: Linux, Windows, macOS (FCM topics not available)
//
// The topic name format MUST match Python's notification_service.py:
//   safe_topic_name = f"channel_{re.sub(r'[^a-zA-Z0-9]', '', channel_name).lower()}"

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHelper {
  NotificationHelper._(); // static-only class

  // ── Platform guard ────────────────────────────────────────────────────────
  // Firebase topic subscription works on Android, iOS, and Web.
  // On Linux/Windows/macOS it will throw, so we skip it silently.
  static bool get _isSupported {
    if (kIsWeb) return true;
    try {
      // dart:io is available on non-web platforms
      // ignore: avoid_dynamic_calls
      const _unused = String.fromEnvironment('dart.library.io'); // suppress unused warning
    } catch (_) {}
    // We rely on try/catch in each method instead of Platform.isAndroid
    // because dart:io Platform is not available on Web.
    return true; // attempt on all platforms; catch handles unsupported ones
  }

  // ── Topic name ────────────────────────────────────────────────────────────
  /// Converts a channel display name into a Firebase-safe topic string.
  /// Must be identical to Python's logic:
  ///   `f"channel_{re.sub(r'[^a-zA-Z0-9]', '', channel_name).lower()}"`
  static String topicName(String channelName) {
    final clean = channelName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    return 'channel_$clean';
  }

  // ── Permission request ────────────────────────────────────────────────────
  /// Call once at app start (or after login).
  /// Safe to call multiple times — Supabase returns cached status after first call.
  static Future<void> initialize() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print(
          '🔔 Notification permission: ${settings.authorizationStatus}');

      // Show notifications even when the app is in the foreground (iOS requires this)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      // Desktop platforms throw here — that is expected
      print('ℹ️ NotificationHelper.initialize skipped on this platform: $e');
    }
  }

  // ── Subscribe ─────────────────────────────────────────────────────────────
  /// Subscribe this device to notifications for [channelName].
  /// Called when the user enables notifications for a channel.
  static Future<void> subscribeToChannel(String channelName) async {
    final topic = topicName(channelName);
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      print('✅ FCM subscribed to topic: $topic');
    } catch (e) {
      print('ℹ️ FCM topic subscribe skipped ($topic): $e');
    }
  }

  // ── Unsubscribe ───────────────────────────────────────────────────────────
  /// Unsubscribe this device from notifications for [channelName].
  /// Called when the user disables notifications OR removes the channel.
  static Future<void> unsubscribeFromChannel(String channelName) async {
    final topic = topicName(channelName);
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      print('🔕 FCM unsubscribed from topic: $topic');
    } catch (e) {
      print('ℹ️ FCM topic unsubscribe skipped ($topic): $e');
    }
  }

  // ── Bulk restore ──────────────────────────────────────────────────────────
  /// Re-subscribe this device to all channels for which the user has
  /// notifications enabled. Call this once right after login so the device
  /// never misses a notification after app reinstall / sign-out-sign-in.
  static Future<void> restoreTopicsForUser(
      List<Map<String, dynamic>> subscriptions) async {
    for (final sub in subscriptions) {
      final name = sub['channel_name'] as String? ?? '';
      final notifEnabled = sub['notifications_enabled'] as bool? ?? false;
      final isSubscribed = sub['is_subscribed'] as bool? ?? false;

      if (isSubscribed && notifEnabled && name.isNotEmpty) {
        await subscribeToChannel(name);
      }
    }
    print('🔄 FCM topics restored for ${subscriptions.length} subscription(s).');
  }
}