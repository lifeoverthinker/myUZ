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
      final tableElements = document.querySelectorAll('table.tabela');

      if (tableElements.isEmpty) {
        Logger.error(
            'Nie znaleziono tabeli grup dla kierunku ${kierunek.nazwa}');
        return [];
      }

      final grupy = <Grupa>[];
      final rows = tableElements.first.querySelectorAll('tr');

      // Pomijamy pierwszy wiersz (nagłówek)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');

        if (cells.isEmpty) {
          Logger.debug('Pomijam pusty wiersz $i');
          continue;
        }

        try {
          // Pobieranie linku i nazwy grupy
          final linkElement = cells[0].querySelector('a');
          if (linkElement == null) {
            Logger.debug('Brak linku do grupy w wierszu $i');
            continue;
          }

          final nazwa = linkElement.text.trim();
          final href = linkElement.attributes['href'];

          if (href == null || href.isEmpty) {
            Logger.debug('Pusty link dla grupy: $nazwa');
            continue;
          }

          // Wyodrębnianie ID grupy z URL
          final idMatch = RegExp(r'id_grupa=(\d+)').firstMatch(href);
          final id = idMatch?.group(1) ?? '';

          if (id.isEmpty) {
            Logger.warning('Nie można wyodrębnić ID grupy z URL: $href');
            continue;
          }

          final url = '$_baseUrl/$href';

          // Pobieranie dodatkowych informacji (jeśli dostępne)
          String rodzajStudiow = '';
          String rokAkademicki = '';
          String semestr = '';

          if (cells.length > 1) rodzajStudiow = cells[1].text.trim();
          if (cells.length > 2) rokAkademicki = cells[2].text.trim();
          if (cells.length > 3) semestr = cells[3].text.trim();

          final grupa = Grupa(
            id: id,
            nazwa: nazwa,
            kierunekId: kierunek.id,
            url: url,
            rodzajStudiow: rodzajStudiow,
            rokAkademicki: rokAkademicki,
            semestr: semestr,
          );

          grupy.add(grupa);
          Logger.debug('Znaleziono grupę: $nazwa, semestr: $semestr');
        } catch (e) {
          Logger.warning('Błąd podczas przetwarzania wiersza $i: $e');
          // Kontynuuj z następnym wierszem
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

  // Metoda pomocnicza do walidacji danych grupy
  List<String> validateGrupaData(Grupa grupa) {
    final errors = <String>[];

    if (grupa.nazwa.isEmpty) {
      errors.add('Brak nazwy grupy');
    }

    if (grupa.id.isEmpty) {
      errors.add('Brak ID grupy');
    }

    if (grupa.kierunekId.isEmpty) {
      errors.add('Brak ID kierunku');
    }

    if (grupa.url.isEmpty) {
      errors.add('Brak URL grupy');
    } else if (!grupa.url.startsWith(_baseUrl)) {
      errors.add('Nieprawidłowy format URL: ${grupa.url}');
    }

    return errors;
  }
}
