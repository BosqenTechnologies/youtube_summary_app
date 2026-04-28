import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Needed for BlocProvider
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_pkg; // Alias to prevent collisions here

import 'features/auth_screen/presentation/screens/auth_screen.dart';
import 'features/youtube_summary/presentation/screens/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/theme_provider.dart';

// --- Clean Architecture Imports for Auth ---
import 'features/auth_screen/data/datasources/auth_remote_data_source.dart';
import 'features/auth_screen/data/repositories/auth_repository_impl.dart';
import 'features/auth_screen/domain/usecases/send_otp_usecase.dart';
import 'features/auth_screen/domain/usecases/verify_otp_usecase.dart';
import 'features/auth_screen/presentation/bloc/auth_cubit.dart';

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
  final supabase = supabase_pkg.Supabase.instance.client;
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

    // Check current session first, then listen to the stream for changes.
    // This prevents the vault from loading before auth is confirmed.
    final currentSession = supabase.auth.currentSession;

    return StreamBuilder<supabase_pkg.AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Use stream data if available, otherwise fall back to the currentSession
        // captured before the stream starts emitting.
        final session = snapshot.hasData
            ? snapshot.data!.session
            : currentSession;

        if (session != null) {
          return const MainScreen();
        }

        // Initialize dependencies for Clean Architecture when showing AuthScreen
        final remoteDataSource = AuthRemoteDataSourceImpl(supabaseClient: supabase);
        final repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);

        // Inject the Cubit so AuthScreen and OtpScreen can use it
        return BlocProvider(
          create: (context) => AuthCubit(
            sendOtpUseCase: SendOtpUseCase(repository),
            verifyOtpUseCase: VerifyOtpUseCase(repository),
          ),
          child: const AuthScreen(),
        );
      },
    );
  }
}