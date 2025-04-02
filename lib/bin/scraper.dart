import 'package:logger/logger.dart';
import 'package:my_uz/services/scraper_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  final logger = Logger();

  try {
    // Inicjalizacja Supabase
    logger.i('🚀 Inicjalizacja Supabase');
    final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
    final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('Brak kluczy Supabase w zmiennych środowiskowych');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    // Uruchomienie scrapera
    logger.i('🔍 Rozpoczęcie scrapowania planów zajęć');
    final scraper = ScraperService();
    await scraper.uruchomScrapowanie();
    logger.i('🎉 Pomyślnie zakończono scrapowanie');
  } catch (e, stackTrace) {
    logger.e('💥 Błąd podczas scrapowania', error: e, stackTrace: stackTrace);
    exit(1);
  }
}