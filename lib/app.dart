import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_summary_app/features/auth_screen/presentation/screens/auth_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/youtube_summary/presentation/screens/main_screen.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TubeSum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 🔥 CHANGED: Point home to AuthGate instead of MainScreen directly
      home: const AuthGate(), 
    );
  }
}

// 🔥 NEW: The AuthGate automatically switches screens based on login status
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listen to Supabase auth state changes in real-time
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show a loading spinner while checking status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Check if we have an active session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User IS logged in! Show your main dashboard.
          return const MainScreen(); 
        }

        // User is NOT logged in. Show the login screen.
        return const AuthScreen();
      },
    );
  }
}