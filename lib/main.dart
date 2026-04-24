import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'firebase_options.dart'; 
import 'app.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    print('⚠️ Firebase init failed or timed out: $e');
  }

  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // 🔥 FIX: Listen for messages when the app is OPEN in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("🔔🔔🔔 PUSH NOTIFICATION RECEIVED IN FOREGROUND! 🔔🔔🔔");
        if (message.notification != null) {
          print("Title: ${message.notification?.title}");
          print("Body: ${message.notification?.body}");
        }
      });

      // Tell Firebase to try to show the notification banner even if the app is open (mostly applies to iOS)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await messaging.getToken();
      print('🔥 FCM Device Token: $token');
    } catch (e) {
      print('⚠️ Firebase Messaging setup failed: $e');
    }
  }

  try {
    await Supabase.initialize(
      url: 'https://vfzfrjjismvlrqbajktp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmemZyamppc212bHJxYmFqa3RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MTkxMjMsImV4cCI6MjA5MDA5NTEyM30.wL5oRPEbH6mbW4lECc47MXLYIK5Rfut5qloktqHg9NY',
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    print('⚠️ Supabase init failed or timed out: $e');
  }

  runApp(const ProviderScope(child: App()));
}