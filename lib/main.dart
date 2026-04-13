import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import
import 'app.dart';

void main() async { // Make this async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase right before the app runs
  await Supabase.initialize(
    url: 'https://vfzfrjjismvlrqbajktp.supabase.co', // Get this from your Supabase Dashboard
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmemZyamppc212bHJxYmFqa3RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1MTkxMjMsImV4cCI6MjA5MDA5NTEyM30.wL5oRPEbH6mbW4lECc47MXLYIK5Rfut5qloktqHg9NY', // Get this from your Supabase Dashboard
  );

  runApp(
    ProviderScope(
      child: const App(),
    ),
  );
}