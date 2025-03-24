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
  final PlanNauczycielaScraper _planNauczycielaScraper = PlanNauczycielaScraper();
  final KierunkiScraper _kierunekScraper = KierunkiScraper();
  final GrupyScraper _grupaScraper = GrupyScraper();
  final ZajeciaScraper _zajeciaScraper = ZajeciaScraper();

  bool _isRunning = false;
  final StreamController<String> _progressController = StreamController<String>.broadcast();

  Stream<String> get progressStream => _progressController.stream;
  bool get isRunning => _isRunning;

  /// Główna metoda uruchamiająca cały proces scrapowania
  Future<void> scrapeAll() async {
    if (_isRunning) {
      throw Exception('Scrapowanie jest już w trakcie');
    }

    _isRunning = true;

    try {
      await _scrapeWydzialy();
      await _scrapeKierunki();
      _progressController.add('Scrapowanie zakończone pomyślnie!');
    } catch (e, stackTrace) {
      _progressController.add('Błąd: $e');
      Logger.error('Błąd scrapowania: $e\n$stackTrace');
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  /// Scrapowanie wydziałów i ich nauczycieli
  Future<void> _scrapeWydzialy() async {
    _progressController.add('Rozpoczynam scrapowanie wydziałów...');
    final wydzialy = await _wydzialScraper.scrapeWydzialy();
    _progressController.add('Znaleziono ${wydzialy.length} wydziałów');

    // Dla każdego wydziału scrapuj nauczycieli
    for (int i = 0; i < wydzialy.length; i++) {
      final wydzial = wydzialy[i];
      _progressController.add('[${i+1}/${wydzialy.length}] Scrapowanie nauczycieli wydziału: ${wydzial.nazwa}');

      // Upewnij się, że mamy ID wydziału
      Wydzial? wydzialWithId;
      if (wydzial.id == null) {
        // Pobierz wydział z bazy danych, który powinien mieć już przypisane ID
        wydzialWithId = await SupabaseService.getWydzialByUrl(wydzial.url);
      } else {
        wydzialWithId = wydzial;
      }

      if (wydzialWithId?.id != null) {
        await _scrapeNauczyciele(wydzialWithId!);
      } else {
        _progressController.add('⚠️ Nie znaleziono ID dla wydziału: ${wydzial.nazwa}');
      }

      // Małe opóźnienie, aby uniknąć przeciążenia serwera
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  /// Scrapowanie nauczycieli dla danego wydziału
  Future<void> _scrapeNauczyciele(Wydzial wydzial) async {
    final nauczyciele = await _nauczycielScraper.scrapeNauczycieleWydzialu(wydzial);
    _progressController.add('Znaleziono ${nauczyciele.length} nauczycieli w wydziale ${wydzial.nazwa}');

    // Pobierz email i plan dla każdego nauczyciela
    for (int i = 0; i < nauczyciele.length; i++) {
      final nauczyciel = nauczyciele[i];
      Logger.info('Pobrano plan nauczyciela: ${nauczyciel.pelneImieNazwisko}');

      // Zapisz lub aktualizuj nauczyciela w bazie
      final savedNauczyciel = await SupabaseService.createOrUpdateNauczyciel(nauczyciel);

      if (savedNauczyciel != null && savedNauczyciel.id != null) {
        // Scrapuj plan nauczyciela
        await _planNauczycielaScraper.scrapePlanNauczyciela(savedNauczyciel);
      }

      // Małe opóźnienie, aby uniknąć przeciążenia serwera
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  /// Scrapowanie kierunków i ich grup
  Future<void> _scrapeKierunki() async {
    _progressController.add('Rozpoczynam scrapowanie kierunków...');
    final kierunki = await _kierunekScraper.scrapeKierunki();
    _progressController.add('Znaleziono ${kierunki.length} kierunków');

    // Dla każdego kierunku scrapuj grupy
    for (int i = 0; i < kierunki.length; i++) {
      final kierunek = kierunki[i];
      _progressController.add('[${i+1}/${kierunki.length}] Scrapowanie grup kierunku: ${kierunek.nazwa}');

      // Upewnij się, że mamy ID kierunku
      final kierunekWithId = await SupabaseService.getKierunekByUrl(kierunek.url) ?? kierunek;

      if (kierunekWithId.id != null) {
        await _scrapeGrupy(kierunekWithId);
      } else {
        _progressController.add('⚠️ Nie znaleziono ID dla kierunku: ${kierunek.nazwa}');
      }

      // Małe opóźnienie, aby uniknąć przeciążenia serwera
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  /// Scrapowanie grup dla danego kierunku
  Future<void> _scrapeGrupy(Kierunek kierunek) async {
    final grupy = await _grupaScraper.scrapeGrupy(kierunek);
    _progressController.add('Znaleziono ${grupy.length} grup w kierunku ${kierunek.nazwa}');

    // Dla każdej grupy scrapuj plan zajęć
    for (int i = 0; i < grupy.length; i++) {
      final grupa = grupy[i];
      _progressController.add('[${i+1}/${grupy.length}] Scrapowanie zajęć grupy: ${grupa.nazwa}');

      if (grupa.id != null) {
        await _zajeciaScraper.scrapeZajecia(grupa);
      } else {
        _progressController.add('⚠️ Brak ID dla grupy: ${grupa.nazwa}');
      }

      // Małe opóźnienie, aby uniknąć przeciążenia serwera
      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  Future<void> runScraper() async {
    if (!AppConfig.enableScraper) {
      Logger.info('Scraper wyłączony w aplikacji mobilnej. Funkcja dostępna tylko w GitHub Actions.');
      _progressController.add('Scraper wyłączony w aplikacji mobilnej');
      return; // Upewnij się, że funkcja tutaj się kończy i nie próbuje wykonać scrapeAll()
    }

    // To się wykona tylko jeśli enableScraper jest true
    await scrapeAll();
  }

  /// Zwalnia zasoby
  void dispose() {
    _progressController.close();
  }
}