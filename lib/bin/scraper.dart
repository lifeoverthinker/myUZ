import 'package:logger/logger.dart';
import 'package:my_uz/services/scraper_service.dart';
import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final logger = Logger();

  try {
    logger.i('🚀 Inicjalizacja Supabase');

    // Pobieranie kluczy ze zmiennych środowiskowych
    final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
        'https://aovlvwjbnjsfplpgqzjv.supabase.co';
    final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdmx2d2pibmpzZnBscGdxemp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5ODY5OTEsImV4cCI6MjA1NzU2Mjk5MX0.TYvFUUhrksgleb-jiLDa-TxdItWuEO_CqIClPYyHdN0';

    // Tworzenie klienta
    final supabaseClient = SupabaseClient(supabaseUrl, supabaseKey);

    logger.i('🔍 Rozpoczęcie scrapowania planów zajęć');
    final scraper = ScraperService(supabaseClient: supabaseClient);
    await scraper.uruchomScrapowanie();
    logger.i('🎉 Pomyślnie zakończono scrapowanie');
  } catch (e, stackTrace) {
    logger.e('💥 Błąd podczas scrapowania', error: e, stackTrace: stackTrace);
    exit(1);
  }
}