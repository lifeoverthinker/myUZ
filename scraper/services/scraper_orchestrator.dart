import 'package:my_uz/services/db/supabase_service.dart';
import '../services/scraper/scraper_zajecia_grupy.dart';
import '../services/scraper/scraper_nauczyciel.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperOrchestrator {
  final SupabaseService _supabaseService;

  ScraperOrchestrator(this._supabaseService);

  Future<void> scrapePlanZajec() async {
    try {
      Logger.info('Rozpoczynanie scrapowania planu zajęć...');

      // Pobieranie danych grup
      await scrapeZajeciaGrupy(_supabaseService);

      // Pobieranie danych nauczycieli
      final nauczyciele = await _supabaseService.getAllNauczyciele();
      await scrapeNauczyciel(nauczyciele, _supabaseService);

      Logger.info('Scrapowanie planu zajęć zakończone pomyślnie.');
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas scrapowania planu zajęć: $e');
      Logger.error('Stack: $stackTrace');
    }
  }
}
