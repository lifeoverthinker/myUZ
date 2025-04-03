import 'package:logger/logger.dart';
import 'package:my_uz/services/scraper_service.dart';
import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  // Utwórz loggera który będzie widoczny w konsoli
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true, // Dodaj wyświetlanie czasu
    ),
    level: Level.info, // Używaj Level.info zamiast trace dla lepszej czytelności
  );

  try {
    logger.i('🚀 Rozpoczynam scraper - czas: ${DateTime.now()}');

    // Sprawdź zmienne środowiskowe
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      logger.w('⚠️ Brak zmiennych środowiskowych, używam wartości domyślnych');
    }

    final url = supabaseUrl ?? 'https://aovlvwjbnjsfplpgqzjv.supabase.co';
    final key = supabaseKey ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdmx2d2pibmpzZnBscGdxemp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODY5OTEsImV4cCI6MjA1NzU2Mjk5MX0.TYvFUUhrksgleb-jiLDa-TxdItWuEO_CqIClPYyHdN0';

    logger.i('Używam URL: $url');

    // Inicjalizacja klienta Supabase
    final supabaseClient = SupabaseClient(url, key);

    // Utwórz scraper z limitem 3 równoległych zadań
    final scraper = ScraperService(
      supabaseClient: supabaseClient,
      logger: logger, // Przekaż logger
      maxRownoleglychZadan: 3, // Zmniejsz liczbę równoległych zadań
    );

    // Ustaw limit czasu na 25 minut
    final timeout = Duration(minutes: 25);
    logger.i('⏱️ Ustawiono timeout: ${timeout.inMinutes} minut');

    // Uruchom scrapowanie z limitem czasu
    await scraper.uruchomScrapowanieZLimitem(timeout);

    logger.i('🎉 Scraper zakończył pracę - czas: ${DateTime.now()}');
  } catch (e, stackTrace) {
    logger.e('💥 Błąd podczas scrapowania', error: e, stackTrace: stackTrace);
    exit(1); // Zakończ z kodem błędu
  }
}