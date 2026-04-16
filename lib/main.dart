import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔥 NEW: Firebase Core
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 NEW: Firebase Messaging
import 'firebase_options.dart'; // 🔥 NEW: Auto-generated Firebase settings
import 'app.dart';

// 🔥 NEW: Background message handler (Must be outside of any class)
// This wakes up your app in the background when a notification arrives
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Set up background messaging listening
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Request Permission for Notifications (Triggers the OS popup)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // 4. Get the Device Token (This is your phone's unique mailing address)
  String? token = await messaging.getToken();
  print('🔥 FCM Device Token: $token'); 

  // 5. Initialize Supabase (Using your exact keys)
  await Supabase.initialize(
    url: 'https://vfzfrjjismvlrqbajktp.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmemZyamppc212bHJxYmFqa3RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MTkxMjMsImV4cCI6MjA5MDA5NTEyM30.wL5oRPEbH6mbW4lECc47MXLYIK5Rfut5qloktqHg9NY',
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}