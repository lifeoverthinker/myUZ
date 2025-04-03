import 'package:flutter/material.dart';
  import 'package:supabase/supabase.dart';
  import 'package:my_uz/config/supabase_config.dart';
  import 'package:my_uz/services/supabase_service.dart';
  import 'package:provider/provider.dart';

  // Globalna instancja
  late SupabaseService supabaseService;

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Inicjalizacja serwisu Supabase
    supabaseService = SupabaseService(
      client: SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
      )
    );

    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return Provider<SupabaseService>.value(
        value: supabaseService,
        child: MaterialApp(
          title: 'MyUZ',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const Placeholder(),
        ),
      );
    }
  }