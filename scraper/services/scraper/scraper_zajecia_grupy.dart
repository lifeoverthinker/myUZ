import 'package:html/parser.dart' as html;
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/services/http_service.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperZajeciaGrupy {
  final HttpService _httpService;
  static const String _baseUrl = 'https://plan.uz.zgora.pl';

  ScraperZajeciaGrupy({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<List<Zajecia>> scrapeZajecia(Grupa grupa) async {
    Logger.info('Rozpoczynam pobieranie zajęć dla grupy: ${grupa.nazwa}');

    try {
      // Generujemy URL na podstawie ID grupy
      final url = '$_baseUrl/grupy.php?ID=${grupa.id}';
      Logger.debug('Pobieranie danych z: $url');
      final response = await _httpService.getBody(url);

      if (response.isEmpty) {
        Logger.warning('Brak danych dla grupy: ${grupa.nazwa}');
        return [];
      }

      final document = html.parse(response);
      final tableElements = document.querySelectorAll('table.tabela');

      if (tableElements.isEmpty) {
        Logger.warning('Brak tabeli z zajęciami dla grupy: ${grupa.nazwa}');
        return [];
      }

      final zajecia = <Zajecia>[];
      final trElements = tableElements.first.querySelectorAll('tr');

      // Pomijamy pierwszy wiersz (nagłówek)
      for (int i = 1; i < trElements.length; i++) {
        final tr = trElements[i];
        final tdElements = tr.querySelectorAll('td');

        if (tdElements.length < 6) {
          Logger.warning('Nieprawidłowy format wiersza w tabeli zajęć');
          continue;
        }

        final przedmiot = tdElements[0].text.trim();
        final rz = tdElements[1].text.trim();
        final miejsce = tdElements[2].text.trim();
        final nauczycielText = tdElements[3].text.trim();
        final terminyText = tdElements[4].text.trim();

        // Konwersja ID grupy na string przy generowaniu UID
        final String generatedUid =
            '${grupa.id.toString()}_${przedmiot}_${rz}_${miejsce}_$i'
                .replaceAll(' ', '_');

        // Parsowanie ID nauczyciela, jeśli jest liczbą
        final int? nauczycielId = int.tryParse(nauczycielText);

        // Domyślne daty
        DateTime odDate = DateTime.now();
        DateTime doDate = DateTime.now().add(Duration(hours: 1));

        final zajecie = Zajecia(
          uid: generatedUid,
          grupaId: grupa.id,
          od: odDate,
          do_: doDate,
          przedmiot: przedmiot,
          rz: rz,
          miejsce: miejsce,
          terminy: terminyText,
          ostatniaAktualizacja: DateTime.now(),
          nauczycielId: nauczycielId,
        );

        zajecia.add(zajecie);
      }

      Logger.info('Pobrano ${zajecia.length} zajęć dla grupy ${grupa.nazwa}');
      return zajecia;
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas pobierania zajęć dla grupy ${grupa.nazwa}', e,
          stackTrace);
      rethrow;
    }
  }
}
