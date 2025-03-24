import 'dart:async';
import 'package:my_uz/models/wydzial.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/utils/logger.dart';
import 'package:my_uz/services/db/supabase_service.dart';
import 'package:my_uz/config/app_config.dart';
import 'package:my_uz/utils/isolate_manager.dart';
import 'scraper/wydzial_scraper.dart';
import 'scraper/nauczyciel_scraper.dart';
import 'scraper/plan_nauczyciela_scraper.dart';
import 'scraper/kierunki_scraper.dart';
import 'scraper/grupy_scraper.dart';
import 'scraper/zajecia_scraper.dart';

class ScraperOrchestrator {
  final WydzialScraper _wydzialScraper = WydzialScraper();
  final NauczycielScraper _nauczycielScraper = NauczycielScraper();
  final PlanNauczycielaScraper _planNauczycielaScraper = PlanNauczycielaScraper();
  final KierunkiScraper _kierunekScraper = KierunkiScraper();
  final GrupyScraper _grupaScraper = GrupyScraper();
  final ZajeciaScraper _zajeciaScraper = ZajeciaScraper();

  bool _isRunning = false;
  final StreamController<String> _progressController = StreamController<String>.broadcast();

  // Konfiguracja równoległości
  final int _concurrentWydzialy = 1;  // Liczba równoległych wydziałów (zwykle 1, bo to podstawowy scraping)
  final int _concurrentNauczyciele = 3;  // Liczba równoległych nauczycieli
  final int _concurrentGrupy = 3;  // Liczba równoległych grup

  Stream<String> get progressStream => _progressController.stream;
  bool get isRunning => _isRunning;

  Future<void> scrapeAll() async {
    if (_isRunning) {
      throw Exception('Scrapowanie jest już w trakcie');
    }

    _isRunning = true;

    try {
      // Uruchomienie głównych zadań równolegle
      await Future.wait([
        _scrapeWydzialy(),
        _scrapeKierunki()
      ]);

      _progressController.add('Scrapowanie zakończone pomyślnie!');
    } catch (e, stackTrace) {
      _progressController.add('Błąd: $e');
      Logger.error('Błąd scrapowania: $e\n$stackTrace');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _scrapeWydzialy() async {
    _progressController.add('Rozpoczynam scrapowanie wydziałów...');
    final wydzialy = await _wydzialScraper.scrapeWydzialy();
    _progressController.add('Znaleziono ${wydzialy.length} wydziałów');

    // Użycie IsolateManager dla wydziałów
    final isolateManager = IsolateManager<Wydzial, void>(
          (wydzial) async {
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
            _progressController.add('⚠️ Nie znaleziono ID dla wydziału: ${wydzial.nazwa}');
          }

          // Opóźnienie między wydziałami
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          Logger.error('Błąd przy przetwarzaniu wydziału ${wydzial.nazwa}: $e');
        }
      },
      name: 'WydzialyProcessor',
      maxConcurrent: _concurrentWydzialy,
    );

    await isolateManager.processBatch(wydzialy);
  }

  Future<void> _scrapeNauczyciele(Wydzial wydzial) async {
    final nauczyciele = await _nauczycielScraper.scrapeNauczycieleWydzialu(wydzial);
    _progressController.add('Znaleziono ${nauczyciele.length} nauczycieli w wydziale ${wydzial.nazwa}');

    // Użycie IsolateManager dla nauczycieli
    final isolateManager = IsolateManager<Map<String, dynamic>, void>(
          (data) async {
        try {
          final nauczyciel = data['nauczyciel'];

          // Zapisz lub aktualizuj nauczyciela w bazie
          final savedNauczyciel = await SupabaseService.createOrUpdateNauczyciel(nauczyciel);

          if (savedNauczyciel != null && savedNauczyciel.id != null) {
            // Scrapuj plan nauczyciela
            await _planNauczycielaScraper.scrapePlanNauczyciela(savedNauczyciel);
          }

          // Opóźnienie między nauczycielami
          await Future.delayed(Duration(milliseconds: 300));
        } catch (e) {
          Logger.error('Błąd przy przetwarzaniu nauczyciela: $e');
        }
      },
      name: 'NauczycieleProcessor',
      maxConcurrent: _concurrentNauczyciele,
    );

    final tasks = nauczyciele.map((n) => {'nauczyciel': n}).toList();
    await isolateManager.processBatch(tasks);
  }

  Future<void> _scrapeKierunki() async {
    _progressController.add('Rozpoczynam scrapowanie kierunków...');
    final kierunki = await _kierunekScraper.scrapeKierunki();
    _progressController.add('Znaleziono ${kierunki.length} kierunków');

    // Użycie IsolateManager dla kierunków
    final isolateManager = IsolateManager<Kierunek, void>(
          (kierunek) async {
        try {
          _progressController.add('Przetwarzanie kierunku: ${kierunek.nazwa}');

          // Upewnij się, że mamy ID kierunku
          final kierunekWithId = await SupabaseService.getKierunekByUrl(kierunek.url) ?? kierunek;

          if (kierunekWithId.id != null) {
            await _scrapeGrupy(kierunekWithId);
          } else {
            _progressController.add('⚠️ Nie znaleziono ID dla kierunku: ${kierunek.nazwa}');
          }

          // Opóźnienie między kierunkami
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          Logger.error('Błąd przy przetwarzaniu kierunku ${kierunek.nazwa}: $e');
        }
      },
      name: 'KierunkiProcessor',
      maxConcurrent: 2,
    );

    await isolateManager.processBatch(kierunki);
  }

  Future<void> _scrapeGrupy(Kierunek kierunek) async {
    final grupy = await _grupaScraper.scrapeGrupy(kierunek);
    _progressController.add('Znaleziono ${grupy.length} grup w kierunku ${kierunek.nazwa}');

    // Użycie IsolateManager dla grup
    final isolateManager = IsolateManager<Map<String, dynamic>, void>(
          (data) async {
        try {
          final grupa = data['grupa'];

          if (grupa.id != null) {
            await _zajeciaScraper.scrapeZajecia(grupa);
          } else {
            _progressController.add('⚠️ Brak ID dla grupy: ${grupa.nazwa}');
          }

          // Opóźnienie między grupami
          await Future.delayed(Duration(milliseconds: 300));
        } catch (e) {
          Logger.error('Błąd przy przetwarzaniu grupy: $e');
        }
      },
      name: 'GrupyProcessor',
      maxConcurrent: _concurrentGrupy,
    );

    final tasks = grupy.map((g) => {'grupa': g}).toList();
    await isolateManager.processBatch(tasks);
  }

  Future<void> runScraper() async {
    if (!AppConfig.enableScraper) {
      Logger.info('Scraper wyłączony w aplikacji mobilnej. Funkcja dostępna tylko w GitHub Actions.');
      _progressController.add('Scraper wyłączony w aplikacji mobilnej');
      return;
    }

    await scrapeAll();
  }

  void dispose() {
    _progressController.close();
  }
}