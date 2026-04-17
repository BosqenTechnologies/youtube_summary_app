import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔥 Firebase Core
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 Firebase Messaging
import 'firebase_options.dart'; // 🔥 Auto-generated Firebase settings
import 'app.dart';

// 🔥 Background message handler (Must be outside of any class)
// Only runs on native platforms (Android/iOS) — not supported on web
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase — wrapped in try-catch + timeout
  // On web release builds, a hanging Future is silently swallowed (no console error)
  // causing the app to never reach runApp() → blank screen.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    print('⚠️ Firebase init failed or timed out: $e');
  }

  // 2. Firebase Messaging setup — skipped on web (not supported)
  if (!kIsWeb) {
    try {
      // Background message handler is not supported on web
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request Permission for Notifications
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // 4. Get the Device Token (requires VAPID key on web, skip here)
      String? token = await messaging.getToken();
      print('🔥 FCM Device Token: $token');
    } catch (e) {
      print('⚠️ Firebase Messaging setup failed: $e');
    }
  }

  // 5. Initialize Supabase — wrapped in try-catch + timeout
  try {
    await Supabase.initialize(
      url: 'https://vfzfrjjismvlrqbajktp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmemZyamppc212bHJxYmFqa3RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MTkxMjMsImV4cCI6MjA5MDA5NTEyM30.wL5oRPEbH6mbW4lECc47MXLYIK5Rfut5qloktqHg9NY',
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    print('⚠️ Supabase init failed or timed out: $e');
  }

  // runApp() is ALWAYS reached — no more blank screens from hanging init calls
  runApp(const ProviderScope(child: App()));
}

