import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/notes/notes_bloc.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tktbpnenzvrtmgexajzi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrdGJwbmVuenZydG1nZXhhanppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MDUxNzAsImV4cCI6MjA4Mzk4MTE3MH0.symmA8okyg1nQn_uGrjHqn-Y6OAz7TNFXkj6WgIlKuk',
  );

  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(supabaseService: supabaseService),
        ),
        BlocProvider<NotesBloc>(
          create: (context) => NotesBloc(supabaseService: supabaseService),
        ),
      ],
      child: MaterialApp(
        title: 'NoteApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}
