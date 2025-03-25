import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/utils/logger.dart';
import 'scraper/nauczyciel_scraper.dart';
import 'scraper/plan_nauczyciela_scraper.dart';

class ScraperOrchestrator {
  final SupabaseService _supabaseService;
  final NauczycielScraper _nauczycielScraper;
  final PlanNauczycielaScraper _planNauczycielaScraper;

  ScraperOrchestrator({
    required SupabaseService supabaseService,
  })  : _supabaseService = supabaseService,
        _nauczycielScraper = NauczycielScraper(),
        _planNauczycielaScraper = PlanNauczycielaScraper();

  Future<void> scrapeAndUpdateNauczyciele() async {
    Logger.info('Rozpoczynanie aktualizacji nauczycieli');

    // Pobierz nauczycieli ze stron UZ
    final nauczyciele = await _nauczycielScraper.scrapeNauczyciele();

    // Zapisz do bazy danych
    for (final nauczyciel in nauczyciele) {
      await _supabaseService.createOrUpdateNauczyciel(nauczyciel);
    }

    Logger.info('Zakończono aktualizację nauczycieli');
  }

  Future<void> scrapeAndUpdatePlanyNauczycieli() async {
    Logger.info('Rozpoczynanie aktualizacji planów nauczycieli');

    // Pobierz wszystkich nauczycieli
    final nauczyciele = await _supabaseService.getAllNauczyciele();
    int count = 0;

    for (final nauczyciel in nauczyciele) {
      // Pobierz plan nauczyciela
      final plany =
          await _planNauczycielaScraper.scrapePlanNauczyciela(nauczyciel);

      // Usuń stare plany
      if (nauczyciel.id != null) {
        await _supabaseService.deleteZajeciaForNauczyciel(nauczyciel.id!);
      }

      // Zapisz nowe plany
      if (plany.isNotEmpty) {
        await _supabaseService.batchInsertPlanyNauczycieli(plany);
      }

      count++;
      if (count % 10 == 0) {
        Logger.info(
            'Zaktualizowano plany $count/${nauczyciele.length} nauczycieli');
      }
    }

    Logger.info('Zakończono aktualizację planów nauczycieli');
  }
}
