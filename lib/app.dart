import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_summary_app/features/auth_screen/presentation/screens/auth_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/youtube_summary/presentation/screens/main_screen.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/theme_provider.dart'; 

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      home: const AuthGate(), 
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;
  bool _isVerifying = true; 

  @override
  void initState() {
    super.initState();
    _verifyUserStatus();
  }

  Future<void> _verifyUserStatus() async {
    final session = supabase.auth.currentSession;

    if (session != null) {
      try {
        await supabase.auth.getUser();
      } catch (e) {
        await supabase.auth.signOut();
      }
    }
    
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const MainScreen(); 
        }

        return const AuthScreen();
      },
    );
  }
}