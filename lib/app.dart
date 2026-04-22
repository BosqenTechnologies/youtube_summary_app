import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🔥 Required for ConsumerWidget
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_summary_app/features/auth_screen/presentation/screens/auth_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/youtube_summary/presentation/screens/main_screen.dart';

// Import your constants
import 'core/constants/app_strings.dart';
import 'core/theme/theme_provider.dart'; // 🔥 Import the new theme provider

// 🔥 CHANGED: App is now a ConsumerWidget so it can listen to theme changes
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 Watch the current theme mode (Light, Dark, or System)
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      
      // 🔥 Apply the themes dynamically here
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      home: const AuthGate(), 
    );
  }
}

// AuthGate is a StatefulWidget that forces a server check
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;
  bool _isVerifying = true; // Shows loading screen until server responds

  @override
  void initState() {
    super.initState();
    _verifyUserStatus();
  }

  Future<void> _verifyUserStatus() async {
    final session = supabase.auth.currentSession;

    // If there is a cached session on the device, double-check it with the server
    if (session != null) {
      try {
        // 🚨 CRITICAL: This pings the server. It fails if the user was deleted.
        await supabase.auth.getUser();
      } catch (e) {
        // The token is invalid or the user was deleted. 
        // Force sign out to destroy the local cache.
        await supabase.auth.signOut();
      }
    }
    
    // Stop loading once the check is done
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show a loader while talking to the Supabase server
    if (_isVerifying) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          // Theme-aware loader
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    // 2. Once verified, listen to the real-time auth stream
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User IS logged in and verified! Show main dashboard.
          return const MainScreen(); 
        }

        // User is NOT logged in or their cache was just wiped. Show login screen.
        return const AuthScreen();
      },
    );
  }
}