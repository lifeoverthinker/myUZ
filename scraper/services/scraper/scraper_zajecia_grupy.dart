import 'package:html/parser.dart' as html;
import 'package:my_uz/models/grupa.dart';
import 'package:my_uz/models/zajecia.dart';
import 'package:my_uz/services/http_service.dart';
import 'package:my_uz/utils/logger.dart';

class ScraperZajeciaGrupy {
  final HttpService _httpService;

  ScraperZajeciaGrupy({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  Future<List<Zajecia>> scrapeZajecia(Grupa grupa) async {
    Logger.info('Rozpoczynam pobieranie zajęć dla grupy: ${grupa.nazwa}');

    try {
      Logger.debug('Pobieranie danych z: ${grupa.url}');
      final response = await _httpService.getBody(grupa.url);

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

        final String generatedUid = 'someUid$i';
        final int? nauczycielId = int.tryParse(tdElements[3].text.trim());
        final int? grupaId = int.tryParse(grupa.id);

        final zajecie = Zajecia(
          uid: generatedUid,
          grupaId: grupaId,
          od: DateTime.now(),
          do_: DateTime.now().add(Duration(hours: 1)),
          przedmiot: tdElements[0].text.trim(),
          rz: tdElements[1].text.trim(),
          miejsce: tdElements[2].text.trim(),
          terminy: 'poniedziałek 10:00-12:00',
          ostatniaAktualizacja: DateTime.now(),
          nauczycielId: nauczycielId,
        );

        zajecia.add(zajecie);
      }

      Logger.info('Pobrano ${zajecia.length} zajęć dla grupy ${grupa.nazwa}');
      return zajecia;
    } catch (e, stackTrace) {
      Logger.error('Błąd podczas pobierania zajęć dla grupy ${grupa.nazwa}', e, stackTrace);
      rethrow;
    }
  }
}