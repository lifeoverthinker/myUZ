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
  final _logger = Logger();

  // Klient HTTP do pobierania stron
  final _klient = http.Client();

  // Klient Supabase do zapisywania danych
  final SupabaseClient _supabase;

  // Parser ICS
  final _icsParser = IcsParser();

  // Maksymalna liczba równoległych zadań
  final int _maxRownoleglychZadan = 10;

  // Konstruktor przyjmujący klienta Supabase
  ScraperService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Główna metoda scrapowania
  Future<void> uruchomScrapowanie() async {
    _logger.i('Rozpoczynam scrapowanie planów zajęć UZ');

    try {
      // 1. Pobieranie i zapisywanie kierunków
      final kierunki = await _pobierzKierunki();
      await _zapiszKierunki(kierunki);
      _logger.i('Pobrano i zapisano ${kierunki.length} kierunków');

      // 2. Pobieranie i zapisywanie grup
      final grupy = await _pobierzGrupy(kierunki);
      await _zapiszGrupy(grupy);
      _logger.i('Pobrano i zapisano ${grupy.length} grup');

      // 3. Pobieranie i zapisywanie zajęć
      final zajecia = await _pobierzZajecia(grupy);
      await _zapiszZajecia(zajecia);
      _logger.i('Pobrano i zapisano ${zajecia.length} zajęć');

      _logger.i('Zakończono scrapowanie planów zajęć');
    } catch (e, stack) {
      _logger.e('Błąd podczas scrapowania: $e', error: e, stackTrace: stack);
      rethrow;
    } finally {
      _klient.close();
    }
  }

  /// Pobiera listę kierunków ze strony
  Future<List<Kierunek>> _pobierzKierunki() async {
    _logger.i('Pobieram listę kierunków');

    final response = await _klient.get(Uri.parse(Constants.listaKierunkowUrl));
    final dokument = parse(response.body);

    final kierunki = <Kierunek>[];
    final wydzialy = dokument.querySelectorAll('div.panel');

    for (final wydzial in wydzialy) {
      final kierunkiElementy = wydzial.querySelectorAll('li.list-group-item a');
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

    return kierunki;
  }

  /// Pobiera grupy dla listy kierunków (wielowątkowo)
  Future<List<Grupa>> _pobierzGrupy(List<Kierunek> kierunki) async {
    _logger.i('Pobieram grupy dla ${kierunki.length} kierunków');

    final wszystkieGrupy = <Grupa>[];
    final futures = <Future<List<Grupa>>>[];
    final pula = _PulaZadan(_maxRownoleglychZadan);

    // Tworzymy zadania do wykonania
    for (final kierunek in kierunki) {
      futures.add(pula.wykonaj(() => _pobierzGrupyDlaKierunku(kierunek)));
    }

    // Czekamy na wyniki i łączymy je
    int ukonczone = 0;
    for (final future in futures) {
      final grupy = await future;
      wszystkieGrupy.addAll(grupy);

      ukonczone++;
      if (ukonczone % 5 == 0 || ukonczone == kierunki.length) {
        _logger.i('Postęp: $ukonczone/${kierunki.length} kierunków');
      }
    }

    return wszystkieGrupy;
  }

  /// Pobiera grupy dla jednego kierunku
  Future<List<Grupa>> _pobierzGrupyDlaKierunku(Kierunek kierunek) async {
    try {
      final response = await _klient.get(Uri.parse(kierunek.url));
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

      return grupy;
    } catch (e) {
      _logger.e('Błąd przy pobieraniu grup dla kierunku ${kierunek.nazwa}: $e');
      return [];
    }
  }

  /// Pobiera zajęcia dla grup poprzez pliki ICS (wielowątkowo)
  Future<List<Zajecia>> _pobierzZajecia(List<Grupa> grupy) async {
    _logger.i('Pobieram zajęcia dla ${grupy.length} grup');

    final wszystkieZajecia = <Zajecia>[];
    final futures = <Future<List<Zajecia>>>[];
    final pula = _PulaZadan(_maxRownoleglychZadan);

    // Tworzymy zadania do wykonania
    for (final grupa in grupy) {
      futures.add(pula.wykonaj(() => _pobierzZajeciaDlaGrupy(grupa)));
    }

    // Czekamy na wyniki i łączymy je
    int ukonczone = 0;
    for (final future in futures) {
      final zajecia = await future;
      wszystkieZajecia.addAll(zajecia);

      ukonczone++;
      if (ukonczone % 20 == 0 || ukonczone == grupy.length) {
        _logger.i('Postęp: $ukonczone/${grupy.length} grup');
      }
    }

    return wszystkieZajecia;
  }

  /// Pobiera zajęcia dla jednej grupy
  Future<List<Zajecia>> _pobierzZajeciaDlaGrupy(Grupa grupa) async {
    try {
      final response = await _klient.get(Uri.parse(grupa.urlIcs));
      if (response.statusCode != 200) {
        _logger.w(
            'Nie udało się pobrać pliku ICS dla grupy ${grupa.id}: ${response.statusCode}');
        return [];
      }

      // Używamy klasy IcsParser zamiast _parsujPlikIcs
      return _icsParser.parsujIcs(response.body, grupaId: grupa.id);
    } catch (e) {
      _logger.e('Błąd podczas pobierania zajęć dla grupy ${grupa.id}: $e');
      return [];
    }
  }

  /// Zapisuje kierunki do bazy Supabase
  Future<void> _zapiszKierunki(List<Kierunek> kierunki) async {
    _logger.i('Zapisuję ${kierunki.length} kierunków do bazy');

    // Zapisujemy w paczkach po 100 elementów
    for (var i = 0; i < kierunki.length; i += 100) {
      final koniec = (i + 100 < kierunki.length) ? i + 100 : kierunki.length;
      final paczka = kierunki.sublist(i, koniec);

      await _supabase
          .from('kierunki')
          .upsert(paczka.map((k) => k.toJson()).toList(), onConflict: 'url');
    }
  }

  /// Zapisuje grupy do bazy Supabase
  Future<void> _zapiszGrupy(List<Grupa> grupy) async {
    _logger.i('Zapisuję ${grupy.length} grup do bazy');

    // Zapisujemy w paczkach po 100 elementów
    for (var i = 0; i < grupy.length; i += 100) {
      final koniec = (i + 100 < grupy.length) ? i + 100 : grupy.length;
      final paczka = grupy.sublist(i, koniec);

      await _supabase.from('grupy').upsert(
          paczka.map((g) => g.toJson()).toList(),
          onConflict: 'url_ics');
    }
  }

  /// Zapisuje zajęcia do bazy Supabase
  Future<void> _zapiszZajecia(List<Zajecia> zajecia) async {
    _logger.i('Zapisuję ${zajecia.length} zajęć do bazy');

    // Zapisujemy w paczkach po 100 elementów
    for (var i = 0; i < zajecia.length; i += 100) {
      final koniec = (i + 100 < zajecia.length) ? i + 100 : zajecia.length;
      final paczka = zajecia.sublist(i, koniec);

      await _supabase
          .from('zajecia')
          .upsert(paczka.map((z) => z.toJson()).toList(), onConflict: 'uid');

      if ((i + 100) % 1000 == 0 || koniec == zajecia.length) {
        _logger.i('Zapisano $koniec/${zajecia.length} zajęć');
      }
    }
  }
}

/// Klasa pomocnicza do ograniczania liczby równoległych zadań
class _PulaZadan {
  final int _maksZadan;
  int _aktualneZadania = 0;
  final _kolejka = <Completer>[];

  _PulaZadan(this._maksZadan);

  Future<void> _zajmijMiejsce() async {
    if (_aktualneZadania < _maksZadan) {
      _aktualneZadania++;
      return Future.value();
    }

    final completer = Completer();
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
