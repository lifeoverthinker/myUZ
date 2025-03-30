import 'package:html/parser.dart' as html;
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/services/http_service.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperGrupy {
  final HttpService _httpService;
  static const String _baseUrl = 'https://plan.uz.zgora.pl';

  ScraperGrupy({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<List<Grupa>> scrapeGrupy(Kierunek kierunek) async {
    Logger.info('Rozpoczynam pobieranie grup dla kierunku: ${kierunek.nazwa}');

    try {
      Logger.debug('Pobieranie danych z: ${kierunek.url}');
      final response = await _httpService.getBody(kierunek.url);

      if (response.isEmpty) {
        Logger.error(
            'Otrzymano pustą odpowiedź przy próbie pobrania grup dla kierunku ${kierunek.nazwa}');
        return [];
      }

      final document = html.parse(response);
      final tableElements = document.querySelectorAll('table.table');

      if (tableElements.isEmpty) {
        Logger.error(
            'Nie znaleziono tabeli grup dla kierunku ${kierunek.nazwa}');
        return [];
      }

      final grupy = <Grupa>[];
      final rows = tableElements.first.querySelectorAll('tr');

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');

        if (cells.isEmpty) {
          Logger.debug('Pomijam pusty wiersz $i');
          continue;
        }

        try {
          final linkElement = cells[0].querySelector('a');
          if (linkElement == null) {
            Logger.debug('Wiersz $i nie zawiera linku');
            continue;
          }

          final nazwa = linkElement.text.trim();
          final href = linkElement.attributes['href'] ?? '';
          final idMatch = RegExp(r'ID=(\d+)').firstMatch(href);
          final id = idMatch?.group(1) ?? '';

          if (id.isEmpty) {
            Logger.warning('Nie można wyodrębnić ID z URL: $href');
            continue;
          }

          // Określanie rodzaju studiów na podstawie nazwy grupy
          String rodzajStudiow = '';
          if (nazwa.toLowerCase().contains('stacjonarne')) {
            rodzajStudiow = 'stacjonarne';
          } else if (nazwa.toLowerCase().contains('niestacjonarne')) {
            rodzajStudiow = 'niestacjonarne';
          }

          // URL do strony planu zajęć grupy (HTML)
          final url = '$_baseUrl/$href';

          // URL do pliku ICS (kalendarz Google)
          final urlIcs = '$_baseUrl/grupy_ics.php?ID=$id&KIND=GG';

          // Pobierz semestr ze strony planu zajęć
          final semestr = await _pobierzSemestrZPlanZajec(url);

          final grupa = Grupa(
            id: int.parse(id),
            nazwa: nazwa,
            kierunekId: int.parse(kierunek.id),
            urlIcs: urlIcs,
            ostatniaAktualizacja: DateTime.now(),
            rodzajStudiow: rodzajStudiow,
            rokAkademicki: '',
            semestr: semestr,
          );

          final errors = validateGrupaData(grupa);
          if (errors.isNotEmpty) {
            Logger.warning('Nieprawidłowe dane grupy: ${errors.join(", ")}');
            continue;
          }

          grupy.add(grupa);
          Logger.debug(
              'Dodano grupę: ${grupa.id} - ${grupa.nazwa}, semestr: ${grupa.semestr}');
        } catch (e) {
          Logger.warning('Błąd podczas przetwarzania wiersza $i: $e');
        }
      }

      Logger.info(
          'Pobrano pomyślnie ${grupy.length} grup dla kierunku ${kierunek.nazwa}');
      return grupy;
    } catch (e, stackTrace) {
      Logger.error(
          'Wystąpił błąd podczas pobierania grup dla kierunku ${kierunek.nazwa}',
          e,
          stackTrace);
      rethrow;
    }
  }

  // Metoda do pobierania informacji o semestrze z nagłówka na stronie planu zajęć
  Future<String> _pobierzSemestrZPlanZajec(String url) async {
    try {
      final response = await _httpService.getBody(url);
      if (response.isEmpty) {
        Logger.warning(
            'Otrzymano pustą odpowiedź przy próbie pobrania strony planu zajęć: $url');
        return '';
      }

      final document = html.parse(response);
      final h3Elements = document.querySelectorAll('h3');

      for (final h3 in h3Elements) {
        final tekst = h3.text.toLowerCase();
        if (tekst.contains('semestr letni')) {
          return 'letni';
        } else if (tekst.contains('semestr zimowy')) {
          return 'zimowy';
        }
      }

      Logger.debug('Nie znaleziono informacji o semestrze na stronie: $url');
      return '';
    } catch (e) {
      Logger.warning('Błąd podczas pobierania informacji o semestrze: $e');
      return '';
    }
  }

  // Metoda pomocnicza do walidacji danych grupy
  List<String> validateGrupaData(Grupa grupa) {
    final errors = <String>[];

    if (grupa.nazwa.isEmpty) {
      errors.add('Brak nazwy grupy');
    }

    if (grupa.id <= 0) {
      errors.add('Nieprawidłowe ID grupy');
    }

    if (grupa.kierunekId <= 0) {
      errors.add('Nieprawidłowe ID kierunku');
    }

    if (grupa.urlIcs.isEmpty) {
      errors.add('Brak URL grupy');
    } else if (!grupa.urlIcs.startsWith(_baseUrl)) {
      errors.add('Nieprawidłowy format URL: ${grupa.urlIcs}');
    }

    return errors;
  }
}
