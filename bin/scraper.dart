import 'dart:io';
import '../scraper/services/scraper_orchestrator.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/services/http_service.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  // Inicjalizacja pliku logów w katalogu tymczasowym
  final tempDir = Directory.systemTemp;
  final logFile = File(path.join(tempDir.path,
      'scraper_log_${DateTime.now().millisecondsSinceEpoch}.txt'));
  Logger.setLogFile(logFile.path);

  Logger.info('Rozpoczynanie scrapera UZ');
  Logger.info('Wersja: 1.0.1');
  Logger.info('Logi zapisywane do: ${logFile.path}');

  // Sprawdź niezbędne zmienne środowiskowe
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    Logger.error('Wymagane zmienne środowiskowe nie są ustawione!');
    Logger.error(
        'SUPABASE_URL i SUPABASE_SERVICE_ROLE_KEY muszą być określone.');
    exit(1);
  }

  int exitCode = 0;

  try {
    // Inicjalizacja serwisów z rozszerzonymi parametrami
    final httpService = HttpService(
      maxRetries: 5,
      retryDelay: const Duration(seconds: 3),
      timeout: const Duration(seconds: 60),
    );

    final dbService = SupabaseService(
      url: supabaseUrl,
      serviceRoleKey: supabaseKey,
    );

    // Ustawienie poziomu logowania na podstawie zmiennej środowiskowej
    final logLevel = Platform.environment['LOG_LEVEL'] ?? 'INFO';
    Logger.info('Poziom logowania: $logLevel');

    // Inicjalizacja orchestratora
    final orchestrator = ScraperOrchestrator(
      dbService: dbService,
      httpService: httpService,
    );

    Logger.info(
        'Konfiguracja serwisów zakończona, rozpoczynam pobieranie danych...');

    // Uruchomienie pełnego scrapowania
    await orchestrator.runFullScrape();

    Logger.info('Proces scrapowania zakończony pomyślnie!');
  } catch (e, stackTrace) {
    Logger.error('Krytyczny błąd podczas wykonywania scrapera', e, stackTrace);
    exitCode = 1;
  } finally {
    // Zapisywanie informacji o zakończeniu
    final endTime = DateTime.now();
    Logger.info('Scraper zakończył działanie o ${endTime.toIso8601String()}');
    Logger.info('Kod wyjścia: $exitCode');

    // Jeśli jesteśmy w środowisku GitHub Actions, wypisz ścieżkę do logów
    if (Platform.environment['GITHUB_ACTIONS'] == 'true') {
      print('::set-output name=log_file::${logFile.path}');
    }
  }

  // Wyjście z kodem błędu lub sukcesu
  exit(exitCode);
}
