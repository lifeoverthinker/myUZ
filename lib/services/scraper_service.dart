import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:logger/logger.dart';
import 'package:my_uz/models/kierunek_model.dart';
import 'package:my_uz/models/grupa_model.dart';
import 'package:my_uz/models/zajecia_model.dart';
import 'package:my_uz/utils/constants.dart';
import 'package:supabase/supabase.dart';
import 'package:my_uz/services/ics_parser.dart';

class ScraperService {
  // Logger do zapisywania informacji
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.trace, // Użyto trace zamiast verbose (deprecated)
  );

  // Klient HTTP do pobierania stron
  final _klient = http.Client();

  // Klient Supabase do zapisywania danych
  final SupabaseClient _supabase;

  // Parser ICS
  final _icsParser = IcsParser();

  // Maksymalna liczba równoległych zadań
  final int _maxRownoleglychZadan = 5;

  // Timeout dla zapytań HTTP
  final Duration _timeout = const Duration(seconds: 20);

  // Flaga przerwania procesu
  bool _czyPrzerwano = false;

  // Konstruktor przyjmujący klienta Supabase
  ScraperService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Metoda do przerwania scrapowania
  void przerwij() {
    _czyPrzerwano = true;
    _logger.w('⚠️ Żądanie przerwania scrapowania...');
  }

  /// Główna metoda scrapowania z limitem czasu
  Future<void> uruchomScrapowanieZLimitem(Duration limit) async {
    return uruchomScrapowanie().timeout(limit, onTimeout: () {
      _logger.w('⏱️ Przekroczony czas całego procesu');
      przerwij();
    });
  }

  /// Główna metoda scrapowania
  Future<void> uruchomScrapowanie() async {
    _logger.i('🚀 Rozpoczynam scrapowanie planów zajęć UZ');

    try {
      // Sprawdzenie połączenia z Supabase
      _logger.i('🔍 Sprawdzam połączenie z bazą danych...');
      await _supabase.from('kierunki').select('id').limit(1);
      _logger.i('✅ Połączenie z Supabase działa poprawnie');

      // 1. Pobieranie i zapisywanie kierunków
      _logger.i('📚 Pobieram listę kierunków...');
      final kierunki = await _pobierzKierunki();

      if (_czyPrzerwano) {
        _logger.w('🛑 Scrapowanie przerwane podczas pobierania kierunków');
        return;
      }

      _logger.i('💾 Zapisuję ${kierunki.length} kierunków do bazy...');
      await _zapiszKierunki(kierunki);
      _logger.i('✅ Zapisano ${kierunki.length} kierunków');

      // 2. Pobieranie i zapisywanie grup
      _logger.i('👥 Pobieram grupy dla ${kierunki.length} kierunków...');
      final grupy = await _pobierzGrupy(kierunki);

      if (_czyPrzerwano) {
        _logger.w('🛑 Scrapowanie przerwane podczas pobierania grup');
        return;
      }

      _logger.i('💾 Zapisuję ${grupy.length} grup do bazy...');
      await _zapiszGrupy(grupy);
      _logger.i('✅ Zapisano ${grupy.length} grup');

      // 3. Pobieranie i zapisywanie zajęć
      _logger.i('📅 Pobieram zajęcia dla ${grupy.length} grup...');
      final zajecia = await _pobierzZajecia(grupy);

      if (_czyPrzerwano) {
        _logger.w('🛑 Scrapowanie przerwane podczas pobierania zajęć');
        return;
      }

      _logger.i('💾 Zapisuję ${zajecia.length} zajęć do bazy...');
      await _zapiszZajecia(zajecia);
      _logger.i('✅ Zapisano ${zajecia.length} zajęć');

      _logger.i('🎉 Zakończono scrapowanie planów zajęć');
    } catch (e, stack) {
      _logger.e('💥 Błąd podczas scrapowania: $e\nTyp błędu: ${e.runtimeType}',
          error: e, stackTrace: stack);
      rethrow;
    } finally {
      _klient.close();
    }
  }

  /// Pobiera listę kierunków ze strony
  Future<List<Kierunek>> _pobierzKierunki() async {
    _logger.i('🔍 Pobieram listę kierunków');

    try {
      final response = await _klient
          .get(Uri.parse(Constants.listaKierunkowUrl))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Timeout podczas pobierania listy kierunków');
      });

      _logger.d('📝 Parsowanie dokumentu HTML');
      final dokument = parse(response.body);

      final kierunki = <Kierunek>[];
      final wydzialy = dokument.querySelectorAll('div.panel');
      _logger.d('🔍 Znaleziono ${wydzialy.length} wydziałów');

      for (final wydzial in wydzialy) {
        final kierunkiElementy =
            wydzial.querySelectorAll('li.list-group-item a');
        for (final kierunekElement in kierunkiElementy) {
          final nazwa = kierunekElement.text.trim();
          final href = kierunekElement.attributes['href'] ?? '';

          // Wyciągamy ID kierunku z URL
          final idMatch = RegExp(r'ID=(\d+)').firstMatch(href);
          if (idMatch != null && idMatch.groupCount >= 1) {
            final id = int.parse(idMatch.group(1)!);
            kierunki.add(Kierunek(
              id: id,
              nazwa: nazwa,
              url: '${Constants.listaGrupUrl}?ID=$id',
            ));
          }
        }
      }

      _logger.i('✅ Pobrano ${kierunki.length} kierunków');
      return kierunki;
    } catch (e, stack) {
      _logger.e(
          '❌ Błąd podczas pobierania kierunków: $e\nTyp błędu: ${e.runtimeType}',
          error: e,
          stackTrace: stack);
      rethrow;
    }
  }

  /// Pobiera grupy dla listy kierunków (wielowątkowo)
  Future<List<Grupa>> _pobierzGrupy(List<Kierunek> kierunki) async {
    _logger.i('👥 Pobieram grupy dla ${kierunki.length} kierunków');

    final wszystkieGrupy = <Grupa>[];
    final futures = <Future<List<Grupa>>>[];
    final pula = _PulaZadan(_maxRownoleglychZadan);

    // Tworzymy zadania do wykonania
    for (final kierunek in kierunki) {
      if (_czyPrzerwano) break;
      futures.add(pula.wykonaj(() => _pobierzGrupyDlaKierunku(kierunek)));
    }

    // Czekamy na wyniki i łączymy je
    int ukonczone = 0;
    for (final future in futures) {
      if (_czyPrzerwano) break;

      try {
        final grupy = await future;
        wszystkieGrupy.addAll(grupy);

        ukonczone++;
        if (ukonczone % 5 == 0 || ukonczone == kierunki.length) {
          _logger.i('Postęp: $ukonczone/${kierunki.length} kierunków');
        }
      } catch (e) {
        _logger.e('❌ Błąd podczas pobierania grup: $e');
      }
    }

    _logger.i(
        '✅ Pobrano grupy dla wszystkich kierunków. Łącznie ${wszystkieGrupy.length} grup');
    return wszystkieGrupy;
  }

  /// Pobiera grupy dla jednego kierunku
  Future<List<Grupa>> _pobierzGrupyDlaKierunku(Kierunek kierunek) async {
    if (_czyPrzerwano) return [];

    try {
      final response = await _klient
          .get(Uri.parse(kierunek.url))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Timeout podczas pobierania grup dla kierunku: ${kierunek.nazwa}');
      });
      final dokument = parse(response.body);

      final grupy = <Grupa>[];
      final wiersze = dokument.querySelectorAll('table.table tbody tr');

      for (final wiersz in wiersze) {
        final komorki = wiersz.querySelectorAll('td');
        if (komorki.length < 2) continue;

        final nazwa = komorki[0].text.trim();
        final elementLinku = komorki[1].querySelector('a');
        final href = elementLinku?.attributes['href'] ?? '';

        // Wyciągamy ID grupy z URL
        final idMatch = RegExp(r'ID=(\d+)').firstMatch(href);
        if (idMatch != null && idMatch.groupCount >= 1) {
          final id = int.parse(idMatch.group(1)!);
          grupy.add(Grupa(
            id: id,
            nazwa: nazwa,
            kierunekId: kierunek.id,
            urlIcs: '${Constants.icsGrupyUrl}?ID=$id&KIND=GG',
          ));
        }
      }

      _logger.d(
          '📊 Pobrano ${grupy.length} grup dla kierunku "${kierunek.nazwa}"');
      return grupy;
    } catch (e) {
      _logger
          .e('❌ Błąd przy pobieraniu grup dla kierunku ${kierunek.nazwa}: $e');
      return [];
    }
  }

  /// Pobiera zajęcia dla grup poprzez pliki ICS (wielowątkowo)
  Future<List<Zajecia>> _pobierzZajecia(List<Grupa> grupy) async {
    _logger.i('📅 Pobieram zajęcia dla ${grupy.length} grup');

    final wszystkieZajecia = <Zajecia>[];
    final futures = <Future<List<Zajecia>>>[];
    final pula = _PulaZadan(_maxRownoleglychZadan);

    // Tworzymy zadania do wykonania
    for (final grupa in grupy) {
      if (_czyPrzerwano) break;
      futures.add(pula.wykonaj(() => _pobierzZajeciaDlaGrupy(grupa)));
    }

    // Czekamy na wyniki i łączymy je
    int ukonczone = 0;
    for (final future in futures) {
      if (_czyPrzerwano) break;

      try {
        final zajecia = await future;
        wszystkieZajecia.addAll(zajecia);

        ukonczone++;
        if (ukonczone % 20 == 0 || ukonczone == grupy.length) {
          _logger.i('Postęp: $ukonczone/${grupy.length} grup');
        }
      } catch (e) {
        _logger.e('❌ Błąd podczas pobierania zajęć: $e');
      }
    }

    _logger.i(
        '✅ Pobrano zajęcia dla wszystkich grup. Łącznie ${wszystkieZajecia.length} zajęć');
    return wszystkieZajecia;
  }

  /// Pobiera zajęcia dla jednej grupy
  Future<List<Zajecia>> _pobierzZajeciaDlaGrupy(Grupa grupa) async {
    if (_czyPrzerwano) return [];

    try {
      final response = await _klient
          .get(Uri.parse(grupa.urlIcs))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Timeout podczas pobierania zajęć dla grupy: ${grupa.id}');
      });

      if (response.statusCode != 200) {
        _logger.w(
            'Nie udało się pobrać pliku ICS dla grupy ${grupa.id}: ${response.statusCode}');
        return [];
      }

      // Używamy klasy IcsParser
      final zajecia = _icsParser.parsujIcs(response.body, grupaId: grupa.id);
      _logger.d('📊 Pobrano ${zajecia.length} zajęć dla grupy ${grupa.id}');
      return zajecia;
    } catch (e) {
      _logger.e('❌ Błąd podczas pobierania zajęć dla grupy ${grupa.id}: $e');
      return [];
    }
  }

  /// Zapisuje kierunki do bazy Supabase
  Future<void> _zapiszKierunki(List<Kierunek> kierunki) async {
    _logger.i('💾 Zapisuję ${kierunki.length} kierunków do bazy');

    try {
      // Zapisujemy w paczkach po 100 elementów
      for (var i = 0; i < kierunki.length; i += 100) {
        if (_czyPrzerwano) break;

        final koniec = (i + 100 < kierunki.length) ? i + 100 : kierunki.length;
        final paczka = kierunki.sublist(i, koniec);

        _logger.d(
            '📤 Zapisuję paczkę kierunków ${i + 1}-$koniec/${kierunki.length}...');
        await _supabase
            .from('kierunki')
            .upsert(paczka.map((k) => k.toJson()).toList(), onConflict: 'url');

        _logger.d(
            '✅ Zapisano paczkę kierunków ${i + 1}-$koniec/${kierunki.length}');
      }
    } catch (e, stack) {
      _logger.e(
          '❌ Błąd podczas zapisywania kierunków: $e\nTyp błędu: ${e.runtimeType}',
          error: e,
          stackTrace: stack);
      rethrow;
    }
  }

  /// Zapisuje grupy do bazy Supabase
  Future<void> _zapiszGrupy(List<Grupa> grupy) async {
    _logger.i('💾 Zapisuję ${grupy.length} grup do bazy');

    try {
      // Zapisujemy w paczkach po 100 elementów
      for (var i = 0; i < grupy.length; i += 100) {
        if (_czyPrzerwano) break;

        final koniec = (i + 100 < grupy.length) ? i + 100 : grupy.length;
        final paczka = grupy.sublist(i, koniec);

        _logger
            .d('📤 Zapisuję paczkę grup ${i + 1}-$koniec/${grupy.length}...');
        await _supabase.from('grupy').upsert(
            paczka.map((g) => g.toJson()).toList(),
            onConflict: 'url_ics');

        _logger.d('✅ Zapisano paczkę grup ${i + 1}-$koniec/${grupy.length}');
      }
    } catch (e, stack) {
      _logger.e(
          '❌ Błąd podczas zapisywania grup: $e\nTyp błędu: ${e.runtimeType}',
          error: e,
          stackTrace: stack);
      rethrow;
    }
  }

  /// Zapisuje zajęcia do bazy Supabase
  Future<void> _zapiszZajecia(List<Zajecia> zajecia) async {
    _logger.i('💾 Zapisuję ${zajecia.length} zajęć do bazy');

    try {
      // Zapisujemy w paczkach po 100 elementów
      for (var i = 0; i < zajecia.length; i += 100) {
        if (_czyPrzerwano) break;

        final koniec = (i + 100 < zajecia.length) ? i + 100 : zajecia.length;
        final paczka = zajecia.sublist(i, koniec);

        _logger.d(
            '📤 Zapisuję paczkę zajęć ${i + 1}-$koniec/${zajecia.length}...');
        await _supabase
            .from('zajecia')
            .upsert(paczka.map((z) => z.toJson()).toList(), onConflict: 'uid');

        if ((i + 100) % 1000 == 0 || koniec == zajecia.length) {
          _logger.i('Zapisano $koniec/${zajecia.length} zajęć');
        }
      }
    } catch (e, stack) {
      _logger.e(
          '❌ Błąd podczas zapisywania zajęć: $e\nTyp błędu: ${e.runtimeType}',
          error: e,
          stackTrace: stack);
      rethrow;
    }
  }
}

/// Klasa pomocnicza do ograniczania liczby równoległych zadań
class _PulaZadan {
  final int _maksZadan;
  int _aktualneZadania = 0;
  final _kolejka = <Completer<void>>[];

  _PulaZadan(this._maksZadan);

  Future<void> _zajmijMiejsce() async {
    if (_aktualneZadania < _maksZadan) {
      _aktualneZadania++;
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _kolejka.add(completer);
    return completer.future;
  }

  void _zwolnijMiejsce() {
    _aktualneZadania--;

    if (_kolejka.isNotEmpty) {
      final completer = _kolejka.removeAt(0);
      _aktualneZadania++;
      completer.complete();
    }
  }

  Future<T> wykonaj<T>(Future<T> Function() zadanie) async {
    await _zajmijMiejsce();
    try {
      return await zadanie();
    } finally {
      _zwolnijMiejsce();
    }
  }
}
