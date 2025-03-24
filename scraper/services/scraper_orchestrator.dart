import 'dart:async';
import 'package:my_uz/models/wydzial.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/config/app_config.dart';
import 'scraper/wydzial_scraper.dart';
import 'scraper/nauczyciel_scraper.dart';
import 'scraper/plan_nauczyciela_scraper.dart';
import 'scraper/kierunki_scraper.dart';
import 'scraper/grupy_scraper.dart';
import 'scraper/zajecia_scraper.dart';

class ScraperOrchestrator {
  final WydzialScraper _wydzialScraper = WydzialScraper();
  final NauczycielScraper _nauczycielScraper = NauczycielScraper();
  final PlanNauczycielaScraper _planNauczycielaScraper =
      PlanNauczycielaScraper();
  final KierunkiScraper _kierunekScraper = KierunkiScraper();
  final GrupyScraper _grupaScraper = GrupyScraper();
  final ZajeciaScraper _zajeciaScraper = ZajeciaScraper();

  bool _isRunning = false;
  final StreamController<String> _progressController =
      StreamController<String>.broadcast();

  // Konfiguracja równoległości
  final int _concurrentWydzialy = 1;
  final int _concurrentNauczyciele = 3;
  final int _concurrentGrupy = 3;

  Stream<String> get progressStream => _progressController.stream;

  bool get isRunning => _isRunning;

  Future<void> scrapeAll() async {
    if (_isRunning) {
      throw Exception('Scrapowanie jest już w trakcie');
    }

    _isRunning = true;

    try {
      // Uruchomienie głównych zadań równolegle
      await Future.wait([_scrapeWydzialy(), _scrapeKierunki()]);

      _progressController.add('Scrapowanie zakończone pomyślnie!');
    } catch (e, stackTrace) {
      _progressController.add('Błąd: $e');
      Logger.error('Błąd scrapowania: $e\n$stackTrace');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  // Pomocnicza metoda do przetwarzania w partiach
  Future<void> _processInBatches<T>(
      List<T> items,
      Future<void> Function(T item) processFunction,
      int concurrentCount) async {
    final batches = <List<T>>[];
    for (var i = 0; i < items.length; i += concurrentCount) {
      final end = (i + concurrentCount < items.length)
          ? i + concurrentCount
          : items.length;
      batches.add(items.sublist(i, end));
    }

    for (final batch in batches) {
      await Future.wait(batch.map((item) => processFunction(item)));
    }
  }

  Future<void> _scrapeWydzialy() async {
    _progressController.add('Rozpoczynam scrapowanie wydziałów...');
    final wydzialy = await _wydzialScraper.scrapeWydzialy();
    _progressController.add('Znaleziono ${wydzialy.length} wydziałów');

    // Zapisz wydziały do bazy danych
    for (final wydzial in wydzialy) {
      await SupabaseService.createOrUpdateWydzial(wydzial);
    }

    // Przetwarzaj wydziały w partiach
    await _processInBatches(wydzialy, _processWydzial, _concurrentWydzialy);
  }

  Future<void> _processWydzial(Wydzial wydzial) async {
    try {
      _progressController.add('Przetwarzanie wydziału: ${wydzial.nazwa}');

      // Upewnij się, że mamy ID wydziału
      Wydzial? wydzialWithId;
      if (wydzial.id == null) {
        wydzialWithId = await SupabaseService.getWydzialByUrl(wydzial.url);
      } else {
        wydzialWithId = wydzial;
      }

      if (wydzialWithId?.id != null) {
        await _scrapeNauczyciele(wydzialWithId!);
      } else {
        _progressController
            .add('⚠️ Nie znaleziono ID dla wydziału: ${wydzial.nazwa}');
      }

      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      Logger.error('Błąd przy przetwarzaniu wydziału ${wydzial.nazwa}: $e');
    }
  }

  Future<void> _scrapeNauczyciele(Wydzial wydzial) async {
    final nauczyciele =
        await _nauczycielScraper.scrapeNauczycieleWydzialu(wydzial);
    _progressController.add(
        'Znaleziono ${nauczyciele.length} nauczycieli w wydziale ${wydzial.nazwa}');

    // Przetwarzaj nauczycieli w partiach
    await _processInBatches(
        nauczyciele, _processNauczyciel, _concurrentNauczyciele);
  }

  Future<void> _processNauczyciel(dynamic nauczyciel) async {
    try {
      // Zapisz lub aktualizuj nauczyciela w bazie
      final savedNauczyciel =
          await SupabaseService.createOrUpdateNauczyciel(nauczyciel);

      if (savedNauczyciel != null && savedNauczyciel.id != null) {
        // Scrapuj plan nauczyciela
        await _planNauczycielaScraper.scrapePlanNauczyciela(savedNauczyciel);
      }

      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      Logger.error('Błąd przy przetwarzaniu nauczyciela: $e');
    }
  }

  Future<void> _scrapeKierunki() async {
    _progressController.add('Rozpoczynam scrapowanie kierunków...');
    final kierunki = await _kierunekScraper.scrapeKierunki();
    _progressController.add('Znaleziono ${kierunki.length} kierunków');

    // Zapisz kierunki do bazy danych
    for (final kierunek in kierunki) {
      await SupabaseService.createOrUpdateKierunek(kierunek);
    }

    // Przetwarzaj kierunki w partiach
    await _processInBatches(kierunki, _processKierunek, 2);
  }

  Future<void> _processKierunek(Kierunek kierunek) async {
    try {
      _progressController.add('Przetwarzanie kierunku: ${kierunek.nazwa}');

      // Upewnij się, że mamy ID kierunku
      final kierunekWithId =
          await SupabaseService.getKierunekByUrl(kierunek.url) ?? kierunek;

      if (kierunekWithId.id != null) {
        await _scrapeGrupy(kierunekWithId);
      } else {
        _progressController
            .add('⚠️ Nie znaleziono ID dla kierunku: ${kierunek.nazwa}');
      }

      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      Logger.error('Błąd przy przetwarzaniu kierunku ${kierunek.nazwa}: $e');
    }
  }

  Future<void> _scrapeGrupy(Kierunek kierunek) async {
    final grupy = await _grupaScraper.scrapeGrupy(kierunek);
    _progressController
        .add('Znaleziono ${grupy.length} grup w kierunku ${kierunek.nazwa}');

    // Przetwarzaj grupy w partiach
    await _processInBatches(grupy, _processGrupa, _concurrentGrupy);
  }

  Future<void> _processGrupa(dynamic grupa) async {
    try {
      if (grupa.id != null) {
        await _zajeciaScraper.scrapeZajecia(grupa);
      } else {
        _progressController.add('⚠️ Brak ID dla grupy: ${grupa.nazwa}');
      }

      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      Logger.error('Błąd przy przetwarzaniu grupy: $e');
    }
  }

  Future<void> runScraper() async {
    if (!AppConfig.enableScraper) {
      Logger.info(
          'Scraper wyłączony w aplikacji mobilnej. Funkcja dostępna tylko w GitHub Actions.');
      _progressController.add('Scraper wyłączony w aplikacji mobilnej');
      return;
    }

    await scrapeAll();
  }

  void dispose() {
    _progressController.close();
  }
}
