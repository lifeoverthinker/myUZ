import 'dart:async';
  import 'dart:io';
  import '../scraper/services/scraper_orchestrator.dart';
  import 'package:my_uz/config/app_config.dart';
  import 'package:my_uz/utils/logger.dart';
  import 'package:my_uz/services/db/supabase_service.dart';

  /// Punkt wejścia dla skryptu scrapera
  Future<void> main() async {
    final stopwatch = Stopwatch()..start();
    Logger.info('Rozpoczynanie procesu scrapowania planu UZ...');

    try {
      // Włącz scraper
      AppConfig.enableScraper = true;

      // Inicjalizacja Supabase
      final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
                           'https://aovlvwjbnjsfplpgqzjv.supabase.co';
      final supabaseKey = Platform.environment['SUPABASE_KEY'] ??
                           'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdmx2d2pibmpzZnBscGdxemp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODY5OTEsImV4cCI6MjA1NzU2Mjk5MX0.TYvFUUhrksgleb-jiLDa-TxdItWuEO_CqIClPYyHdN0';

      Logger.info('Inicjalizacja połączenia z Supabase...');
      // Inicjalizujemy serwis zamiast tworzyć zmienną
      SupabaseService.initialize(supabaseUrl, supabaseKey);
      Logger.info('Połączenie z Supabase nawiązane pomyślnie');

      // Utworzenie orkiestratora
      final orchestrator = ScraperOrchestrator();

      // Nasłuchiwanie na postęp
      orchestrator.progressStream.listen((message) {
        Logger.info(message);
      });

      // Uruchomienie scrapera
      Logger.info('Uruchamianie pełnego scrapera...');
      await orchestrator.runScraper();

      final elapsedTime = stopwatch.elapsed;
      Logger.info(
          'Proces scrapowania zakończony pomyślnie w ${elapsedTime.inMinutes}m ${elapsedTime.inSeconds % 60}s');
    } catch (e, stackTrace) {
      Logger.error('Wystąpił błąd: $e');
      Logger.error('Stack trace: $stackTrace');
      exit(1);
    } finally {
      exit(0);
    }
  }