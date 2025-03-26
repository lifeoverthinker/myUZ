import 'package:html/parser.dart' as html;
import 'package:my_uz/models/kierunek.dart';
import 'package:my_uz/services/http_service.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperKierunki {
  final HttpService _httpService;
  static const String _baseUrl = 'https://plan.uz.zgora.pl';
  static const String _kierunkiPath = '/index.php';

  ScraperKierunki({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<List<Kierunek>> scrapeKierunki() async {
    Logger.info('Rozpoczynam pobieranie kierunków studiów');

    try {
      final url = '$_baseUrl$_kierunkiPath';
      Logger.debug('Pobieranie danych z: $url');

      final response = await _httpService.getBody(url);

      if (response.isEmpty) {
        Logger.error(
            'Otrzymano pustą odpowiedź przy próbie pobrania kierunków');
        return [];
      }

      final document = html.parse(response);
      final tableElements = document.querySelectorAll('table.tabela');

      if (tableElements.isEmpty) {
        Logger.error('Nie znaleziono tabeli kierunków studiów');
        return [];
      }

      final kierunki = <Kierunek>[];
      final rows = tableElements.first.querySelectorAll('tr');

      // Pomijamy pierwszy wiersz (nagłówek)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');

        if (cells.length < 2) {
          Logger.debug(
              'Pomijam nieprawidłowy wiersz z ${cells.length} komórkami');
          continue;
        }

        try {
          // Pobieranie linku i nazwy kierunku
          final linkElement = cells[0].querySelector('a');
          if (linkElement == null) {
            Logger.debug('Brak linku do kierunku w wierszu $i');
            continue;
          }

          final nazwa = linkElement.text.trim();
          final href = linkElement.attributes['href'];

          if (href == null || href.isEmpty) {
            Logger.debug('Pusty link dla kierunku: $nazwa');
            continue;
          }

          // Pobieranie wydziału (jeśli dostępny)
          final wydzial = cells.length > 1 ? cells[1].text.trim() : '';

          // Wyodrębnianie ID kierunku z URL
          final idMatch = RegExp(r'id_kierunek=(\d+)').firstMatch(href);
          final id = idMatch?.group(1) ?? '';

          if (id.isEmpty) {
            Logger.warning('Nie można wyodrębnić ID kierunku z URL: $href');
            continue;
          }

          final url = '$_baseUrl/$href';

          final kierunek = Kierunek(
            id: id,
            nazwa: nazwa,
            wydzial: wydzial,
            url: url,
          );

          kierunki.add(kierunek);
          Logger.debug('Znaleziono kierunek: $nazwa, wydział: $wydzial');
        } catch (e) {
          Logger.warning('Błąd podczas przetwarzania wiersza $i: $e');
          // Kontynuuj z następnym wierszem
        }
      }

      Logger.info('Pobrano pomyślnie ${kierunki.length} kierunków studiów');
      return kierunki;
    } catch (e, stackTrace) {
      Logger.error(
          'Wystąpił błąd podczas pobierania kierunków studiów', e, stackTrace);
      rethrow;
    }
  }

  // Metoda pomocnicza do walidacji danych kierunków
  List<String> validateKierunekData(Kierunek kierunek) {
    final errors = <String>[];

    if (kierunek.nazwa.isEmpty) {
      errors.add('Brak nazwy kierunku');
    }

    if (kierunek.id.isEmpty) {
      errors.add('Brak ID kierunku');
    }

    if (kierunek.url.isEmpty) {
      errors.add('Brak URL kierunku');
    } else if (!kierunek.url.startsWith(_baseUrl)) {
      errors.add('Nieprawidłowy format URL: ${kierunek.url}');
    }

    return errors;
  }
}
