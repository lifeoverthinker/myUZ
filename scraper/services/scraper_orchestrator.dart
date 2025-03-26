import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/models/nauczyciel.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/services/http_service.dart';
import '../services/scraper/scraper_grupy.dart';
import '../services/scraper/scraper_kierunki.dart';
import '../services/scraper/scraper_nauczyciel.dart';
import '../services/scraper/scraper_zajecia_grupy.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperOrchestrator {
  final SupabaseService _dbService;

  final ScraperKierunki _kierunkiScraper;
  final ScraperGrupy _grupyScraper;
  final ScraperZajeciaGrupy _zajeciaScraper;
  final ScraperNauczyciel _nauczycielScraper;

  ScraperOrchestrator({
    required SupabaseService dbService,
    HttpService? httpService,
  })  : _dbService = dbService,
        _kierunkiScraper = ScraperKierunki(httpService: httpService),
        _grupyScraper = ScraperGrupy(httpService: httpService),
        _zajeciaScraper = ScraperZajeciaGrupy(httpService: httpService),
        _nauczycielScraper = ScraperNauczyciel(httpService: httpService);

  Future<void> runFullScrape() async {
    Logger.info('Rozpoczynam pełny proces scrapowania');

    try {
      // 1. Pobierz kierunki
      Logger.info('Etap 1: Pobieranie kierunków');
      final kierunki = await _scrapeAndSaveKierunki();

      if (kierunki.isEmpty) {
        throw Exception('Nie udało się pobrać żadnych kierunków');
      }

      Logger.info('Pobrano ${kierunki.length} kierunków');

      // 2. Dla każdego kierunku pobierz grupy
      Logger.info('Etap 2: Pobieranie grup dla kierunków');
      final grupy = await _scrapeAndSaveGrupy(kierunki);

      if (grupy.isEmpty) {
        throw Exception('Nie udało się pobrać żadnych grup');
      }

      Logger.info('Pobrano ${grupy.length} grup');

      // 3. Dla każdej grupy pobierz zajęcia
      Logger.info('Etap 3: Pobieranie zajęć dla grup');
      final zajecia = await _scrapeAndSaveZajecia(grupy);

      Logger.info('Pobrano ${zajecia.length} zajęć');

      // 4. Pobierz dane wszystkich nauczycieli znalezionych w zajęciach
      Logger.info('Etap 4: Pobieranie danych nauczycieli');
      await _scrapeAndSaveNauczyciele();

      Logger.info('Zakończono pełny proces scrapowania');
    } catch (e, stackTrace) {
      Logger.error(
          'Wystąpił krytyczny błąd podczas procesu scrapowania', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Kierunek>> _scrapeAndSaveKierunki() async {
    try {
      final kierunki = await _kierunkiScraper.scrapeKierunki();

      // Zapisz kierunki do bazy danych
      final savedKierunki = <Kierunek>[];
      for (final kierunek in kierunki) {
        await _dbService.createOrUpdateKierunek(kierunek);
        savedKierunki.add(kierunek);
      }

      return savedKierunki;
    } catch (e, stackTrace) {
      Logger.error(
          'Błąd podczas pobierania i zapisywania kierunków', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Grupa>> _scrapeAndSaveGrupy(List<Kierunek> kierunki) async {
    final allGrupy = <Grupa>[];

    for (final kierunek in kierunki) {
      try {
        Logger.info('Pobieranie grup dla kierunku: ${kierunek.nazwa}');
        final grupy = await _grupyScraper.scrapeGrupy(kierunek);

        // Zapisz grupy do bazy danych
        for (final grupa in grupy) {
          await _dbService.createOrUpdateGrupa(grupa);
          allGrupy.add(grupa);
        }

        Logger.info(
            'Pobrano ${grupy.length} grup dla kierunku ${kierunek.nazwa}');
      } catch (e) {
        Logger.warning(
            'Błąd podczas pobierania grup dla kierunku ${kierunek.nazwa}: $e');
        // Kontynuuj z następnym kierunkiem
      }
    }

    return allGrupy;
  }

  Future<List<Zajecia>> _scrapeAndSaveZajecia(List<Grupa> grupy) async {
    final allZajecia = <Zajecia>[];
    int processedCount = 0;
    final totalGrupy = grupy.length;

    for (final grupa in grupy) {
      try {
        Logger.info(
            'Pobieranie zajęć dla grupy: ${grupa.nazwa} (${processedCount + 1}/$totalGrupy)');
        final zajecia = await _zajeciaScraper.scrapeZajecia(grupa);

        // Zapisz zajęcia do bazy danych
        for (final zajecie in zajecia) {
          await _dbService.saveZajecia([zajecie]);
          allZajecia.add(zajecie);
        }

        Logger.info('Pobrano ${zajecia.length} zajęć dla grupy ${grupa.nazwa}');
        processedCount++;
      } catch (e) {
        Logger.warning(
            'Błąd podczas pobierania zajęć dla grupy ${grupa.nazwa}: $e');
        // Kontynuuj z następną grupą
      }

      // Małe opóźnienie, aby nie przeciążać serwera
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return allZajecia;
  }

  Future<void> _scrapeAndSaveNauczyciele() async {
    try {
      // Pobierz wszystkie unikalne ID nauczycieli z zajęć
      final List<int> nauczycielIds = await _dbService.getUniqueNauczycielIds();
      Logger.info(
          'Znaleziono ${nauczycielIds.length} unikalnych nauczycieli do pobrania');

      int success = 0;
      int failure = 0;

      for (final id in nauczycielIds) {
        try {
          final nauczyciel = await _nauczycielScraper.scrapeNauczyciel(id.toString());
          if (nauczyciel != null) {
            await _dbService.saveNauczyciel(nauczyciel);
            success++;
            Logger.info('Pobrano dane nauczyciela: ${nauczyciel.nazwa}');
          } else {
            Logger.warning('Nie udało się pobrać danych nauczyciela o ID: $id');
            failure++;
          }
        } catch (e) {
          Logger.warning('Błąd podczas pobierania danych nauczyciela $id: $e');
          failure++;
        }
      }

      Logger.info(
          'Zakończono pobieranie danych nauczycieli. Sukces: $success, Niepowodzenia: $failure');
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas pobierania danych nauczycieli', e, stackTrace);
      rethrow;
    }
  }

  // Metoda do ponowienia scrapowania konkretnego nauczyciela po ID
  Future<Nauczyciel?> rescrapeNauczyciel(String id) async {
    try {
      Logger.info('Ponowne pobieranie danych nauczyciela o ID: $id');
      final nauczyciel = await _nauczycielScraper.scrapeNauczyciel(id);

      if (nauczyciel != null) {
        await _dbService.saveNauczyciel(nauczyciel);
        Logger.info(
            'Pomyślnie zaktualizowano dane nauczyciela: ${nauczyciel.nazwa}');
      }

      return nauczyciel;
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas ponownego pobierania danych nauczyciela $id',
          e, stackTrace);
      return null;
    }
  }
}